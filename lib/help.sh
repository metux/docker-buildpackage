
help() {
    local progname="$1"
    echo "$progname [--help] [--create-baseimage] [--target=<target>]"
    exit 0

}

version() {
    echo "dck-buildpackage version $VERSION"
    echo "Copyright (C) 2018 Enrico Weigelt, metux IT consult <info@metux.net>"
    echo "This is free software, released under the GNU Affero Public License Version 3+"
    exit 0
}
