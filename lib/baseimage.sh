
baseimage_die() {
    die "[baseimage] FAILED: $*"
}

baseimage_info() {
    info "[baseimage] $*"
}

baseimage_builder_init() {
    BASEIMAGE_ROOTFS="$(cf_distro_debootstrap_chroot)"
    baseimage_info "builder type: sudo"
    baseimage_info "creating rootfs: ${BASEIMAGE_ROOTFS}"
    [ "${BASEIMAGE_ROOTFS}" ] || baseimage_die "no rootfs path"
    baseimage_builder_exec rm -Rf "${BASEIMAGE_ROOTFS}"
    baseimage_builder_exec mkdir -p "${BASEIMAGE_ROOTFS}" || baseimage_die "mkdir ${BASEIMAGE_ROOTFS}"
}

baseimage_builder_exec() {
    baseimage_info "builder exec: $@"
    sudo "$@"
    return $?
}

baseimage_builder_destroy() {
    [ "${BASEIMAGE_ROOTFS}" ] || baseimage_die "no rootfs path"
    baseimage_info "destroying rootfs: ${BASEIMAGE_ROOTFS}"
    baseimage_builder_exec rm -Rf "${BASEIMAGE_ROOTFS}"
}

baseimage_rootfs_exec() {
    baseimage_info "exec in rootfs: $@"
    baseimage_builder_exec chroot "${BASEIMAGE_ROOTFS}" "$@"
}

create_baseimage() {
    local baseimage_name=$(cf_distro_baseimage_name)
    local baseimage_id=$(docker_find_image "${baseimage_name}")
    local tarball_tmp=$(cf_distro_debootstrap_tarball)
    local debootstra_args=""

    if [ "$baseimage_id" ]; then
        baseimage_info "docker image already exists: ${baseimage_id} ... skipping"
        return 0
    fi

    if [ -f "${tarball_tmp}" ]; then
        baseimage_info "rootfs tarball already exists: ${tarball_tmp} ... loading it"
        docker_import_tarball "${tarball_tmp}" "${baseimage_name}"
        return $?
    fi

    local keyring=$(cf_distro_keyring)

    [ "$DISTRO_ARCH" ]       && debootstrap_args="$debootstrap_args --arch=$DISTRO_ARCH"
    [ "$DISTRO_INCLUDE" ]    && debootstrap_args="$debootstrap_args --include=$DISTRO_INCLUDE"
    [ "$DISTRO_EXCLUDE" ]    && debootstrap_args="$debootstrap_args --exclude=$DISTRO_EXCLUDE"
    [ "$DISTRO_COMPONENTS" ] && debootstrap_args="$debootstrap_args --components=$DISTRO_COMPONENTS"
    [ "$DISTRO_VARIANT" ]    && debootstrap_args="$debootstrap_args --variant=$DISTRO_VARIANT"
    [ "$keyring" ]           && debootstrap_args="$debootstrap_args --keyring=$keyring"

    [ "$DISTRO_SCRIPT" ]     || DISTRO_SCRIPT="${DCK_BUILDPACKAGE_CFDIR}/bootstrap/$DISTRO_NAME"

    baseimage_info "no rootfs tarball: ${tarball_tmp} ... creating it"

    baseimage_builder_init

    baseimage_info "running debootstrap: ${DISTRO_NAME} / ${DISTRO_ARCH}"

    baseimage_builder_exec apt-get update
    baseimage_builder_exec apt-get install -y debootstrap

    baseimage_builder_exec debootstrap \
        $debootstrap_args \
        "${DISTRO_NAME}" \
        "${BASEIMAGE_ROOTFS}" \
        "${DISTRO_MIRROR}" \
        "${DISTRO_SCRIPT}" || baseimage_die "debootstrap"

    baseimage_info "configure extra apt repos"

    if [ "$DISTRO_APT_SOURCES" ]; then
        echo "$DISTRO_APT_SOURCES" | baseimage_rootfs_exec bash -c 'cat >> /etc/apt/sources.list' || baseimage_die "failed adding apt sources"
    fi

    baseimage_info "installing extra packages"

    if [ "$DISTRO_EXTRA_PACKAGES" ]; then
        baseimage_rootfs_exec apt-get install -y $DISTRO_EXTRA_PACKAGES || baseimage_die "install extra packages: ${DISTRO_EXTRA_PACKAGES}"
    fi

    baseimage_info "marking unneeded packages as auto"

    [ "$DISTRO_MARK_AUTO" ] && baseimage_rootfs_exec apt-mark auto $DISTRO_MARK_AUTO

    baseimage_info "removing unneeded packages"

    baseimage_rootfs_exec apt-get autoremove -y
    baseimage_rootfs_exec apt-get autoclean
    baseimage_rootfs_exec apt-get remove -y --purge $(baseimage_rootfs_exec dpkg -l | grep "^rc" | awk '{print $2}' | tr '\n' ' ')

    baseimage_info "extra package removal"

    for i in $DISTRO_REMOVE_PACKAGES ; do
        baseimage_info " ... removing: $i"
        baseimage_rootfs_exec dpkg --force-remove-essential --remove "$i"
        baseimage_rootfs_exec dpkg --force-remove-essential --purge "$i"
    done

    baseimage_info "removing unwanted files"

    [ "$DISTRO_REMOVE_FILES" ] && baseimage_rootfs_exec rm -Rf $DISTRO_REMOVE_FILES

    baseimage_info "creating rootfs tarball"

    mkdir -p `dirname "$tarball_tmp"` || baseimage_die "failed creating tarball dir"
    baseimage_builder_exec tar -C "${BASEIMAGE_ROOTFS}" -c . > "$tarball_tmp" || baseimage_die "failed taring chroot"

    baseimage_info "importing docker image"

    docker_import_tarball "${tarball_tmp}" "${baseimage_name}"

    baseimage_info "cleanup"

    baseimage_builder_destroy

    return $?
}

cmd_create_baseimage() {
    [ "$DCK_BUILDPACKAGE_TARGET" ] || baseimage_die "missing --target <distro> parameter"
    info "RUNNING BASEIMAGE: $DCK_BUILDPACKAGE_TARGET"
    load_dist_conf
    create_baseimage || baseimage_die "failed to create base image"
    info "FINISHED"
}
