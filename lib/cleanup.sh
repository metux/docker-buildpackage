
cmd_cleanup() {
    info "CLEANUP"

    $(get_docker_cmd) ps -qa -f "name=$(cf_build_container_prefix)" | \
        while read n ; do info "Destroying container: $n"; docker_destroy "$n" || true; done

    docker_volume_remove $(get_aptcache_volumes)

    info "DONE"
}
