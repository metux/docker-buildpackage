
docker_find_image() {
    [ "$1" ] && $(get_docker_cmd) images -q "$1"
}

docker_volume_create() {
    local volume_id="$1"

    if $(get_docker_cmd) volume inspect "$volume_id" >/dev/null 2>/dev/null; then
        return 0
    fi

    if ! $(get_docker_cmd) volume create "$volume_id" >/dev/null; then
        die "docker volume $volume_id cant be created"
    fi
}

docker_volume_remove() {
    while [ "$1" ]; do
        info "Removing volume: $1"
        $(get_docker_cmd) volume rm "$1"
        shift
    done
}

docker_volume_list() {
    $(get_docker_cmd) volume ls -q
}

docker_init_container() {
    local container_id
    local container_name="$2"
    local container_base="$1"

    if [ "$container_name" ]; then
        container_id=`$(get_docker_cmd) create --hostname "$container_name" --name "$container_name" "$container_base" $(get_init_cmd)`
    else
        container_id=`$(get_docker_cmd) create "$container_base" $(get_init_cmd)`
    fi

    [ "$container_id" ] || die "failed to create container"
    info "Created container: $container_id"
    echo -n "$container_id"
}

docker_exec_sh() {
    local container_id="$1"
    shift
    $(get_docker_cmd) exec "$container_id" sh -c "$*"
}

docker_destroy() {
    local container_id="$1"
    $(get_docker_cmd) kill "$container_id"
    $(get_docker_cmd) rm "$container_id"
}

docker_cp_from() {
    local container_id="$1"
    local src="$2"
    local dst="$3"
    mkdir -p $dst
    $(get_docker_cmd) cp "$container_id:$src" "$dst"
}

docker_cp_to() {
    local container_id="$1"
    local src="$2"
    local dst="$3"
    docker_exec_sh "$container_id" mkdir -p "$dst" || die "failed to mkdir in container: $dst"
    info $(get_docker_cmd) cp "$src" "$container_id:$dst"
    $(get_docker_cmd) cp "$src" "$container_id:$dst"
}

docker_set_apt_proxy() {
    local container_id="$1"
    local proxy="$2"

    if [ "$proxy" ]; then
        info "configuring http proxy: $proxy"
        docker_exec_sh $container_id "echo \"Acquire::http::Proxy \\\"$proxy\\\";\" > /etc/apt/apt.conf.d/99proxy"
    fi
}

docker_set_apt_sources() {
    local container_id="$1"
    local ent="$2"

    if [ "$ent" ]; then
        info "adding extra apt sources entries: $ent"
        docker_exec_sh $container_id "echo \"$ent\" >> /etc/apt/sources.list"
    fi
}

docker_apt_update() {
    local container_id="$1"
    docker_exec_sh $container_id "apt-get update"
}

docker_container_start() {
    local baseimage="$1"; shift
    local name="$1"; shift
    info "Starting docker container: $name ($baseimage)"
    $(get_docker_cmd) run -d --name "$name" "$@" "$baseimage" "$(get_init_cmd)"
}
