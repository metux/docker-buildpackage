
log() {
    echo "LOG: $*" >&2
}

info() {
    echo "INFO: $*" >&2
}

die() {
    echo "FAILED: $*" >&2
    exit 1
}
