
__run_build() {
    local src_dir="$1"
    local key="$(cf_build_container_prefix)$DISTRO_TAG-$(uuidgen)"
    local baseimage_name=$(cf_distro_baseimage_name)
    local baseimage_id=$(docker_find_image $baseimage_name)
    local current_user=$(whoami)
    local build_dir="$(cf_container_build_prefix)/$(basename "$src_dir")"
    local pkg_name=$(debsrc_pkg_name $src_dir)

    info "Building package: $pkg_name"

    local build_container_id=`docker_container_start $baseimage_name "$key" -v "$(cf_distro_aptcache_volume):$(get_aptcache_dir)"`

    docker_set_apt_proxy $build_container_id "$DISTRO_PROXY"

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
