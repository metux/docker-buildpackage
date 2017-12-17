
## copy out an package from docker instance into local repo
aptrepo_copy_from_docker() {
    local container_id="$1"
    local container_dir="$2"
    local prefix="$3"

    local debfiles=`docker_exec_sh $container_id find $container_dir -maxdepth 1 -name "*.deb"`
    local pool_dir="$(cf_distro_target_repo)/pool/dists/$DISTRO_NAME/$DISTRO_COMPONENT"
    info "apt repo pool dir=$pool_dir"
    mkdir -p $pool_dir
    for i in $debfiles ; do
        info "remote debfile: $i"
        docker_cp_from $container_id "$i" $pool_dir/
    done
}
