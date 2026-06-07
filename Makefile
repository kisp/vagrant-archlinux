RELEASE_DATESTAMP := $(shell date +'%Y%m')
BOX_NAME := vagrant-archlinux-test-$(RELEASE_DATESTAMP)

# All qcow2 images (Packer-built base, run-qemu.sh overlays, saved snapshots)
# live in this single directory, which carries a CACHEDIR.TAG so backups skip
# it. Packer cannot write into an existing directory, so it still builds into
# a temporary staging dir and build-qemu moves the artifact here.
IMAGES_DIR := images

# Optional build-time features. Pass NIX=1 to either build target to install
# and enable Nix (with flakes) in the image, e.g. `make build-qemu NIX=1`.
# This just maps to the Packer variable enable_nix.
ifdef NIX
export PKR_VAR_enable_nix := true
endif

build:
	packer build -var-file isovars.pkrvars.hcl archbox.pkr.hcl

# Build a bootable qcow2 disk image (no Vagrant/VirtualBox involved).
# Packer builds into the staging dir output-archlinux-qemu/ (it refuses to
# write into an existing directory), then we move the image into $(IMAGES_DIR).
build-qemu:
	rm -rf output-archlinux-qemu
	packer build -var-file isovars.pkrvars.hcl archbox-qemu.pkr.hcl
	mkdir -p $(IMAGES_DIR)
	mv output-archlinux-qemu/*.qcow2 $(IMAGES_DIR)/
	rm -rf output-archlinux-qemu

# Boot the newest qcow2 image straight in this terminal (serial console)
run-qemu:
	./run-qemu.sh

clean:
	rm -f archlinux-x64-*.box

# Remove all qcow2 images (base, overlays, snapshots) but keep the CACHEDIR.TAG
# so the directory stays marked for backup tools.
clean-qemu:
	rm -rf output-archlinux-qemu
	rm -f $(IMAGES_DIR)/*.qcow2

init:
	packer init archbox.pkr.hcl
	packer init archbox-qemu.pkr.hcl

list-boxes:
	vagrant box list

add-box:
	vagrant box add $(BOX_NAME) archlinux-x64-$(RELEASE_DATESTAMP).box --force

remove-box:
	vagrant box remove $(BOX_NAME)

start-vm:
	vagrant up
	vagrant ssh

destroy-vm:
	vagrant destroy -f

upload:
	./upload.sh
