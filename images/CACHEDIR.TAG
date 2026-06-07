Signature: 8a477f597d28d172789f06886806bc55
# This file is a cache directory tag created for vagrant-archlinux.
#
# It marks this directory as containing regenerable cache data so that
# backup tools skip it. Everything here is a large qcow2 image (the Packer-built
# base, run-qemu.sh overlays, saved provisioned snapshots) that can be rebuilt
# with `make build-qemu`, so none of it belongs in backups.
#
# Honoured by e.g.:
#   restic backup --exclude-caches
#   borg create --exclude-caches
#   tar --exclude-caches
#
# For information about cache directory tags, see:
#   https://bford.info/cachedir/
