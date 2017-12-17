
debsrc_pkg_name() {
    local srcdir="$1"
    [ -f $srcdir/debian/control ] || die "call me from within a debianized source tree"
    local pkg_name=`grep -e "^Source:" < $srcdir/debian/control | sed -e 's~^Source: ~~; s~ ~~g;'`
    for i in $pkg_name ; do
        echo -n "$i"
        return 0
    done
    die "failed to extract package name"
}
