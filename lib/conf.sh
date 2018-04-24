
load_dist_conf() {
    DISTRO_TAG="$DCK_BUILDPACKAGE_TARGET"

    [ "$DCK_BUILDPACKAGE_TARGET_REPO" ] || export DCK_BUILDPACKAGE_TARGET_REPO="$HOME/dckbp-apt-repo"

    [ "$DISTRO_TAG" ] || die "no target distro specified. use --target <dist> option"

    [ "$DCK_BUILDPACKAGE_CONFDIR" ] && DCK_BUILDPACKAGE_CFDIR="$DCK_BUILDPACKAGE_CONFDIR"

    . $DCK_BUILDPACKAGE_CFDIR/target/$DCK_BUILDPACKAGE_TARGET.cf || die "loading dist config for $DISTRO_TAG"

    [ "$DISTRO_NAME"             ] || die "dist config: missing DISTRO_NAME"
    [ "$DISTRO_ARCH"             ] || die "dist config: missing DISTRO_ARCH"
    [ "$DISTRO_COMPONENTS"       ] || die "dist config: missing DISTRO_COMPONENTS"
    [ "$DISTRO_MIRROR"           ] || die "dist config: missing DISTRO_MIRROR"
    [ "$DISTRO_INCLUDE"          ] || die "dist config: missing DISTRO_INCLUDE"
    [ "$DISTRO_INIT_CMD"         ] || export DISTRO_INIT_CMD="/sbin/init"
    [ "$DISTRO_TARGET_NAME"      ] || export DISTRO_TARGET_NAME="$DISTRO_NAME"
    [ "$DISTRO_TARGET_COMPONENT" ] || export DISTRO_TARGET_COMPONENT="contrib"
    [ "$DISTRO_TARGET_REPO"      ] || export DISTRO_TARGET_REPO="$DCK_BUILDPACKAGE_TARGET_REPO/$DISTRO_TAG/"

    [ "$DISTRO_APT_ARCHS"        ] || export DISTRO_APT_ARCHS="$DISTRO_ARCH"

    # check whether docker is too old for volume command
    if docker volume 2>&1 | grep "is not a docker command" >/dev/null; then
        info "docker is too old for volume command. disabling apt-cache volume"
        unset DISTRO_APT_USE_CACHE_VOLUME
    fi
}

get_init_cmd() {
    echo -n "$DISTRO_INIT_CMD"
}

get_docker_cmd() {
    if [ "$DCK_BUILDPACKAGE_DOCKER_CMD" ]; then
        echo -n "$DCK_BUILDPACKAGE_DOCKER_CMD"
    else
        echo -n "sudo docker"
    fi
}

get_dpkg_opts() {
    if [ "$DCK_BUILDPACKAGE_DPKG_OPTS" ]; then
        echo -n "$DCK_BUILDPACKAGE_DPKG_OPTS"
    elif [ "$DISTRO_DPKG_OPTS" ]; then
        echo -n "$DISTRO_DPKG_OPTS"
    else
        echo -n "-b -uc -us"
    fi
}

get_deb_dir() {
    local debdir="$DCK_BUILDPACKAGE_DEB_DIR"
    [ "$debdir" ] || debdir="../deb"
    ( cd $WORK_SRC_DIR && readlink -f "$debdir" )
}

cf_distro_target_repo() {
    echo -n "$DISTRO_TARGET_REPO"
}

## distro's keyring file to use
cf_distro_keyring() {
    [ "$DISTRO_KEYRING" ] || return 0

    case "$DISTRO_KEYRING" in
        /*)
            echo -n "$DISTRO_KEYRING"
        ;;
        *)
            readlink -f "$DCK_BUILDPACKAGE_CFDIR/$DISTRO_KEYRING"
    esac
}

## build prefix within container
cf_container_build_prefix() {
    echo -n "/dck-buildpackage/src"
}

## get the distro's base image name
cf_distro_baseimage_name() {
    if [ "$DCK_BUILDPACKAGE_BASE_IMAGE" ]; then
        echo -n "$DCK_BUILDPACKAGE_BASE_IMAGE"
    else
        if [ "$DISTRO_BASE_IMAGE" ]; then
            echo -n "$DISTRO_BASE_IMAGE"
        else
            echo -n "dckbp-baseimage-$DISTRO_TAG"
        fi
    fi
}

## get the distro's apt cache volume name
cf_distro_aptcache_volume() {
    if [ "$DCK_BUILDPACKAGE_APTCACHE_VOLUME" ]; then
        echo -n "$DCK_BUILDPACKAGE_APTCACHE_VOLUME"
    else
        echo -n "dckbp-aptacache-$DISTRO_TAG"
    fi
}

## temporary dir for debootstrap
cf_distro_debootstrap_chroot() {
    echo -n "/tmp/dck-buildpackage/debootstrap-images/$DCK_BUILDPACKAGE_TARGET"
}

## docker build container name prefix
cf_build_container_prefix() {
    echo -n "dckbp-build-"
}

## prefix for build-time copy of source tree on host side (will be mounted into container)
cf_host_src_prefix() {
    [ "$TEMP" ] || TEMP=/tmp
    local prefix="$TEMP/dck-buildpackage-src.$(whoami)"
    mkdir -p $prefix
    echo -n "$prefix"
}
