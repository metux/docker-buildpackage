
create_baseimage() {
    local baseimage_name=$(cf_distro_baseimage_name)
    local baseimage_id=$(docker_find_image $baseimage_name)
    local chroot_tmp=$(cf_distro_debootstrap_chroot)
    local debootstra_args=""

    if [ "$baseimage_id" ]; then
        info "base image already exists: $baseimage_id ... skipping"
        return 0
    fi

    sudo rm -Rf $chroot_tmp
    sudo mkdir -p $chroot_tmp || die "mkdir $chroot_tmp"

    local keyring=$(cf_distro_keyring)

    [ "$DISTRO_ARCH" ]       && debootstrap_args="$debootstrap_args --arch=$DISTRO_ARCH"
    [ "$DISTRO_INCLUDE" ]    && debootstrap_args="$debootstrap_args --include=$DISTRO_INCLUDE"
    [ "$DISTRO_COMPONENTS" ] && debootstrap_args="$debootstrap_args --components=$DISTRO_COMPONENTS"
    [ "$keyring" ]           && debootstrap_args="$debootstrap_args --keyring=$keyring"

    sudo debootstrap \
        $debootstrap_args \
        "${DISTRO_NAME}" \
        "$chroot_tmp" \
        "${DISTRO_MIRROR}" || die "debootstrap"

    for i in $DISTRO_MARK_AUTO ; do
        sudo chroot $chroot_tmp apt-mark auto "$i"
    done

    sudo chroot $chroot_tmp apt-get autoremove -y
    sudo chroot $chroot_tmp apt-get autoclean

    sudo tar -C $chroot_tmp -c . | $(get_docker_cmd) import \
        - $baseimage_name

    sudo rm -Rf $chroot_tmp
}

cmd_create_baseimage() {
    [ "$DCK_BUILDPACKAGE_TARGET" ] || die "missing --target <distro> parameter"
    info "RUNNING BASEIMAGE"
    load_dist_conf
    create_baseimage || die "failed to create base image"
    info "FINISHED"
}
