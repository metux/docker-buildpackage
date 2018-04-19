
VERSION=0.1

set -e

. $DCK_BUILDPACKAGE_LIBDIR/log.sh
. $DCK_BUILDPACKAGE_LIBDIR/docker.sh
. $DCK_BUILDPACKAGE_LIBDIR/help.sh
. $DCK_BUILDPACKAGE_LIBDIR/aptcache.sh
. $DCK_BUILDPACKAGE_LIBDIR/baseimage.sh
. $DCK_BUILDPACKAGE_LIBDIR/build.sh
. $DCK_BUILDPACKAGE_LIBDIR/cleanup.sh
. $DCK_BUILDPACKAGE_LIBDIR/conf.sh
. $DCK_BUILDPACKAGE_LIBDIR/aptrepo.sh
. $DCK_BUILDPACKAGE_LIBDIR/dpkg.sh

parse_args() {
    local progname="$1"
    shift

    current_cmd="build"

    while [ "$1" ]; do
        case "$1" in
            "--help")
                help "$progname"
            ;;
            "--version"|"-v")
                version "$progname"
            ;;
            "--target")
                shift
                DCK_BUILDPACKAGE_TARGET="$1"
            ;;
            "--cleanup"|"--clean")
                current_cmd="cleanup"
            ;;
            "--update-aptrepo")
                current_cmd="update-aptrepo"
            ;;
            *)
                WORK_SRC_DIR=$(readlink -f $1)
            ;;
        esac
        shift
    done
}

parse_args "$0" "$@"

[ "$WORK_SRC_DIR" ] || WORK_SRC_DIR=$(readlink -f .)

case "$current_cmd" in
    "build")
        cmd_build
    ;;
    "cleanup")
        cmd_cleanup
    ;;
    "update-aptrepo")
        cmd_update_aptrepo
    ;;
    *)
        help "$progname"
    ;;
esac
