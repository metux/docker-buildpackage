
baseimage_die() {
    die "[baseimage] FAILED: $*"
}

baseimage_info() {
    info "[baseimage] $*"
}

create_baseimage() {
    local baseimage_name=$(cf_distro_baseimage_name)
    local baseimage_id=$(docker_find_image "${baseimage_name}")
    local chroot_tmp=$(cf_distro_debootstrap_chroot)
    local debootstra_args=""

    if [ "$baseimage_id" ]; then
        baseimage_info "docker image already exists: ${baseimage_id} ... skipping"
        return 0
    fi

    sudo rm -Rf "${chroot_tmp}"
    sudo mkdir -p "${chroot_tmp}" || baseimage_die "mkdir ${chroot_tmp}"

    local keyring=$(cf_distro_keyring)

    [ "$DISTRO_ARCH" ]       && debootstrap_args="$debootstrap_args --arch=$DISTRO_ARCH"
    [ "$DISTRO_INCLUDE" ]    && debootstrap_args="$debootstrap_args --include=$DISTRO_INCLUDE"
    [ "$DISTRO_EXCLUDE" ]    && debootstrap_args="$debootstrap_args --exclude=$DISTRO_EXCLUDE"
    [ "$DISTRO_COMPONENTS" ] && debootstrap_args="$debootstrap_args --components=$DISTRO_COMPONENTS"
    [ "$DISTRO_VARIANT" ]    && debootstrap_args="$debootstrap_args --variant=$DISTRO_VARIANT"
    [ "$keyring" ]           && debootstrap_args="$debootstrap_args --keyring=$keyring"

    [ "$DISTRO_SCRIPT" ]     || DISTRO_SCRIPT="${DCK_BUILDPACKAGE_CFDIR}/bootstrap/$DISTRO_NAME"

    baseimage_info "running debootstrap: ${DISTRO_NAME} / ${DISTRO_ARCH}"

    sudo debootstrap \
        $debootstrap_args \
        "${DISTRO_NAME}" \
        "${chroot_tmp}" \
        "${DISTRO_MIRROR}" \
        "${DISTRO_SCRIPT}" || baseimage_die "debootstrap"

    baseimage_info "configure extra apt repos"

    if [ "$DISTRO_APT_SOURCES" ]; then
        echo "$DISTRO_APT_SOURCES" | sudo chroot "${chroot_tmp}" bash -c 'cat >> /etc/apt/sources.list' || baseimage_die "failed adding apt sources"
    fi

    baseimage_info "installing extra packages"

    if [ "$DISTRO_EXTRA_PACKAGES" ]; then
        sudo chroot "${chroot_tmp}" apt-get install -y $DISTRO_EXTRA_PACKAGES || baseimage_die "install extra packages: ${DISTRO_EXTRA_PACKAGES}"
    fi

    baseimage_info "marking unneeded packages as auto"

    for i in $DISTRO_MARK_AUTO ; do
        sudo chroot "${chroot_tmp}" apt-mark auto "$i"
    done

    baseimage_info "removing unneeded packages"

    sudo chroot "${chroot_tmp}" apt-get autoremove -y
    sudo chroot "${chroot_tmp}" apt-get autoclean

    sudo chroot "${chroot_tmp}" apt-get remove -y --purge $(sudo chroot "${chroot_tmp}" dpkg -l | grep "^rc" | awk '{print $2}' | tr '\n' ' ')

    baseimage_info "extra package removal"

    for i in $DISTRO_REMOVE_PACKAGES ; do
        baseimage_info " ... removing: $i"
        sudo chroot "${chroot_tmp}" dpkg --force-remove-essential --remove "$i"
        sudo chroot "${chroot_tmp}" dpkg --force-remove-essential --purge "$i"
    done

    baseimage_info "removing unwanted files"

    for i in $DISTRO_REMOVE_FILES ; do
        sudo chroot "${chroot_tmp}" rm -Rf "$i"
    done

    baseimage_info "importing docker image"

    sudo tar -C "${chroot_tmp}" -c . | $(get_docker_cmd) import \
        - "${baseimage_name}"

    baseimage_info "cleanup"

    sudo rm -Rf "${chroot_tmp}"
}

cmd_create_baseimage() {
    [ "$DCK_BUILDPACKAGE_TARGET" ] || baseimage_die "missing --target <distro> parameter"
    info "RUNNING BASEIMAGE: $DCK_BUILDPACKAGE_TARGET"
    load_dist_conf
    create_baseimage || baseimage_die "failed to create base image"
    info "FINISHED"
}
