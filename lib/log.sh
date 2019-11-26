
_color_yellow() {
    echo -ne "\e[33m"
}

_color_normal() {
    echo -ne "\e[39m"
}

_color_green() {
    echo -ne "\e[32m"
}

_color_red() {
    echo -ne "\e[91m"
}

log() {
    ( _color_yellow ; echo -n "LOG: " ; _color_normal ; echo "$*" ) >&2
}

info() {
    ( _color_green ; echo -n "INFO: " ; _color_normal ; echo "$*" ) >&2
}

die() {
    ( _color_red ; echo -n "FAILED: " ; _color_normal ; echo "$*" ) >&2
    exit 1
}
