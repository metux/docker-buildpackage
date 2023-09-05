CHANGES
=======

v0.5
----

* baseimage: support bootstrapping in docker container
  - use docker container instead of sudo for debootstrap run
  - enabled when image is defined via `$DISTRO_BUILDER_IMAGE`
  - enabled it for Devuan targets

* baseimage: optimized post-install steps _(eg. apt-mark or file removal)_
  - formerly was done by looping through lists and calling the jail'ed commands separately
  - now running in one command, thus only entering the jail once
  - downside: can't use wildcards anymore _(would be expanded outside jail/container)_

* baseimage: automatically install debootstrap
  - bootstrapping jail might not have debootstrap installed, so install it automatically
  - needed for dockerized bootstrapping w/ offical images

* baseimage: caching rootfs tarballs
  - rootfs tarballs are now cached and automatically reused _(used to be temporary-only)_
  - helpful for CI's that always run fresh environments, but are able to cache/restore individual directories
  - cache prefix can be defined via `$DCK_BUILDPACKAGE_TARBALL_CACHE`
  - default is still `/tmp/dck-buildpackage/debootstrap-tarballs/`

* baseimage: support setting distro variant to bootstrap
  - target configs now can set it via `$DISTRO_VARIANT`
  - passed as `--variant` parameter to debootstrap

* builder: fix missing `/tmp` inside container
  - rootfs images might be heavily trimmed down and lacking `/tmp`
  - make sure it always exists before doing anything else

* targets: Devuan: fix missing `usr-is-merged` package
  - on recent Debian, debootstrap wants to install `usr-is-merged`, which is not present on older releases
  - since it's never needed on Devuan, just add it to the `$DISTRO_EXCLUDE` list

* targets: Devuan: rename `dng-*` targets to `devuan-*`
  - Fixing target naming scheme
  - Old names kept for backwards compatibility

* targets: additions and removals
  - add: Devuan Daedalus
  - add: Devuan Testing
  - add: Devuan Unstable
  - drop: Devuan ASCII and Jessie _(dead)_

v0.4
----

* baseimage: add setting for extra packages
  - `$DISTRO_EXTRA_PACKAGES` config variable for installing extra packages
  - installing happens before the cleanup phase

* baseimage: use bundled bootstrap scripts
  - some hosts lacking the right bootstrap scripts for certain distros
  - keeping a bundled copy, which will be maintained along w/ target configs

* builder: fix untrusted local repos
  - Recent apt refuses to install from untrusted repos
  - locally built repo needs to be explicitly set as trusted

* builder: autogenerate `debian/changes` when needed
  - some packages want their debian/changes file generated `debian/rules`
  - calling `./debian/rules debian/changes` in that case

* targets: additions and removals:
  - add: Devuan Beowulf
  - add: Devuan Chimaera
  - add: Ubuntu Focal
  - drop: Ubuntu Trusty _(dead)_

* targets: consolidated target configs
  - consolidate common parts from arch specific distro targets
  - most things now done in common include's
  - per release includes that are just referenced by per arch targets
  - consolidated keyring files
  - updated debootstrap scrips

v0.3
----

* builder: fix broken permissions after build:
  - Container's temporary source tree _(fed in by the outside)_ can become inaccessible to host user
  - Fixing it inside the container by just removing it

* builder: fix unnecessary chown of generated apt repo
  - picking out deb's and generating apt indices now runs as unprivileged user
  - no need to `sudo chown` anymore

* builder: record latest deb file names
  - debs of last build run collected at: `<repo-prefix>/stat/<distro>/<pkg>/latest-debs`
  - higher level tools can pick it from there, e.g. for automatic tests

* builder: ccache support
  - ccache data put into a separate volume called `dckbp-ccache-$DISTRO_TAG`

* builder: generate `debian/control`
  - Some packages need to generate `debian/control` by `debian/rules`
  - installing deps via `debian/control.bootstrap`, then call `debian/rules` to generate `debian/control`

* builder: allow passing source package name via environment
  - Some packages need to use a different source package name
  - This can be passed via `$DCK_BUILDPACKAGE_SOURCE` environment variable

* builder: check for uuidgen tool
  - Sanity check for uuidgen tool installed
  - Prevent silent failures that could go unnoticed and corrupt build

* targets: additions
  - Debian Stretch (i386/amd64)
  - Devuan ASCII (i386)

* targets: fix devuan apt repo
  - Devuan's mirror cluster (auto.mirror.devuan.org) seems unstable
  - using primary mirror: http://deb.devuan.org/merged
  - Updated keyring
