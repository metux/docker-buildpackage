
get_ccache_dir() {
    echo -n "/var/cache/ccache"
}

get_ccache_volumes() {
    docker_volume_list | grep -e "^dckbp-ccache-"
}

create_ccache_volume() {
    local volume_id=$(cf_distro_ccache_volume)
    info "ccache volume: $volume_id"
    docker_volume_create $volume_id
}
