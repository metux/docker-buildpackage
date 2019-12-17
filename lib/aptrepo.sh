
aptrepo_prepare() {
    mkdir -p "$(cf_distro_target_repo)"
}

## copy out an package from docker instance into local repo
aptrepo_copy_from_docker() {
    local container_id="$1"
    local container_dir="$2"
    local pkgname="$3"
    local myuid="$(id -u)"
    local mygid="$(id -g)"

    local debfiles=`docker_exec_sh $container_id find $container_dir -maxdepth 1 -name "*.deb"`
    local pool_subdir="pool/dists/$DISTRO_NAME/$DISTRO_TARGET_COMPONENT/$pkgname"
    local pool_dir="$(cf_distro_target_repo)/$pool_subdir"
    local stat_file="$(cf_distro_target_repo)/stat/$pkgname/latest-debs"
    info "apt repo pool dir=$pool_dir"
    mkdir -p $(dirname "$stat_file")
    echo -n > $stat_file
    for i in $debfiles ; do
        info "remote debfile: $i"
        docker_cp_from $container_id "$i" $pool_dir
        echo "$pool_subdir/$(basename $i)" >> $stat_file
    done
    info "fixing apt repo permissions: $(cf_distro_target_repo)"
    sudo chown "$myuid:$mygid" $(cf_distro_target_repo)
}

_aptrepo_tmpl() {
    local cfdir="$DCK_BUILDPACKAGE_CFDIR/apt"
    local fn="$1"
    local repo_dir="$(cf_distro_target_repo)"

    mkdir -p $repo_dir/conf
    cat $cfdir/$fn.tmpl \
        | sed -e "s~@SECTIONS@~$DISTRO_TARGET_COMPONENT~g;" \
        | sed -e "s~@ARCHITECTURES@~$DISTRO_APT_ARCHS~g;" \
        | sed -e "s~@DISTRO@~$DISTRO_TARGET_NAME~g; " \
        | sed -e "s~@CODENAME@~$DISTRO_TARGET_NAME~g;" \
        | sed -e "s~@LABEL@~$DISTRO_TARGET_NAME~g;" \
        | sed -e "s~@COMPONENTS@~$DISTRO_TARGET_COMPONENT~g;" \
        | sed -e "s~@DESCRIPTION@~locally built by $(whoami)@$(hostname) via dck-buildpackage -- https://github.com/metux/docker-buildpackage~g;" \
        > $repo_dir/conf/$fn
}

aptrepo_update() {
    local repo_dir="$(cf_distro_target_repo)"
    local dist_root="$repo_dir/dists/$DISTRO_TARGET_NAME"

    [ "$repo_dir" ] || die "apt repo dir undefined"

    info "apt repo dir: $repo_dir"

    _aptrepo_tmpl apt-ftparchive.conf

    rm -rf $repo_dir/cache

    mkdir -p $repo_dir/cache \
             $repo_dir/pool/dists/$DISTRO_TARGET_NAME/$DISTRO_TARGET_COMPONENT \
             $dist_root/$DISTRO_TARGET_COMPONENT/binary-$DISTRO_ARCH/ \

    for a in $DISTRO_APT_ARCHS ; do
        mkdir -p $dist_root/$DISTRO_TARGET_COMPONENT/binary-$a
        touch $dist_root/$DISTRO_TARGET_COMPONENT/binary-$a/Packages
    done

    (cd $repo_dir && apt-ftparchive generate $repo_dir/conf/apt-ftparchive.conf \
                  && apt-ftparchive -c $repo_dir/conf/apt-ftparchive.conf release $dist_root > $dist_root/Release.tmp \
                  && mv $dist_root/Release.tmp $dist_root/Release ) || die "apt-ftparchive failed"

    rm -f $dist_root/Release.gpg $repo_dir/apt-repo.pub

    if [ "$DCK_BUILDPACKAGE_SIGNKEY" ]; then
        GPG_SIGN_PARAM="-u $DCK_BUILDPACKAGE_SIGNKEY"
        GPG_EXPORT_PARAM="$DCK_BUILDPACKAGE_SIGNKE"Y
        info "Using GPG key: $DCK_BUILDPACKAGE_SIGNKEY"
        gpg -u "$DCK_BUILDPACKAGE_SIGNKEY" -abs -o $dist_root/Release.gpg $dist_root/Release || die 'signing failed. did you create a key ? maybe set $DCK_BUILDPACKAGE_SIGNKEY'
        gpg --output "$repo_dir/apt-repo.pub" --armor --export "$DCK_BUILDPACKAGE_SIGNKEY"  || die 'key export failed. did you create a key ?'
    else
        info 'Using default GPG key. You might want to spefify key ID via $DCK_BUILDPACKAGE_SIGNKEY'
        gpg -abs -o $dist_root/Release.gpg $dist_root/Release || die 'signing failed. did you create a key ? maybe set $DCK_BUILDPACKAGE_SIGNKEY'
        gpg --output "$repo_dir/apt-repo.pub" --armor --export || die 'key export failed. did you create a key ?'
    fi

    info "FINISHED apt repo: $repo_dir"
}

# regenerate the local apt repo index
cmd_update_aptrepo() {
    load_dist_conf
    aptrepo_update
}
