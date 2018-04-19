
__run_build() {
    local src_dir="$1"
    local key="$(cf_build_container_prefix)$DISTRO_TAG-$(uuidgen)"
    local baseimage_name=$(cf_distro_baseimage_name)
    local baseimage_id=$(docker_find_image $baseimage_name)
    local current_user=$(whoami)
    local build_dir="$(cf_container_build_prefix)/$(basename "$src_dir")"
    local pkg_name=$(debsrc_pkg_name $src_dir)
    local container_param=""
    local local_repo="/local-repo"

    info "Building package: $pkg_name"

    if [ "$DISTRO_APT_USE_BUILT_REPO" ]; then
        info "Using locally built apt repo: $(cf_distro_target_repo)"
        container_param="-v $(cf_distro_target_repo):$local_repo"
        extra_sources="deb file://$local_repo $DISTRO_TARGET_NAME $DISTRO_TARGET_COMPONENT"
    fi

    info "starting container"
    local build_container_id=`docker_container_start $baseimage_name "$key" -v "$(cf_distro_aptcache_volume):$(get_aptcache_dir)" $container_param`

    docker_set_apt_proxy $build_container_id "$DISTRO_PROXY"
    docker_set_apt_sources $build_container_id "$DISTRO_APT_EXTRA_SOURCES"

    if [ "$DISTRO_APT_USE_BUILT_REPO" ]; then
        info "adding local apt repo"
        docker_exec_sh $build_container_id "apt-key add $local_repo/apt-repo.pub"
        docker_set_apt_sources $build_container_id "$extra_sources"
    fi

    docker_apt_update $build_container_id

    info "copying source tree $src_dir into container $build_container_id ($build_dir)"
    docker_cp_to $build_container_id $src_dir $(dirname $build_dir)

    info "install package's build dependencies"
    docker_exec_sh $build_container_id "cd $build_dir ; mk-build-deps -i -t 'apt-get -o Debug::pkgProblemResolver=yes -y --no-install-recommends'" || die "failed installing build deps"

    info "run the build"
    docker_exec_sh $build_container_id "cd $build_dir ; dpkg-buildpackage $(get_dpkg_opts)" || die "failed to build package"

    info "copy out built packages"
    aptrepo_copy_from_docker $build_container_id $(dirname $build_dir) $pkg_name

    info "destroying temporary build container"
    docker_destroy "$build_container_id"

    if [ "$DISTRO_APT_AUTO_REGENERATE" ]; then
        info "calling target apt repo regenerate"
        aptrepo_update
    fi
}

cmd_build() {
    [ "$DCK_BUILDPACKAGE_TARGET" ] || die "missing --target <distro> parameter"
    info "RUNNING BUILD"
    load_dist_conf
    create_baseimage || die "failed to create base image"
    create_aptcache_volume || die "failed to create aptcache volume"
    __run_build "$WORK_SRC_DIR" || die "build failed"
    info "FINISHED"
}
