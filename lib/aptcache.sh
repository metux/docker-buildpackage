
get_aptcache_dir() {
    echo -n "/var/cache/apt/archives"
}

get_aptcache_volumes() {
    docker_volume_list | grep -e "^dckbp-aptacache-"
}

create_aptcache_volume() {
    local volume_id=$(cf_distro_aptcache_volume)
    info "apt-cache volume: volume_id"
    docker_volume_create $volume_id
}
