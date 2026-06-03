RELEASE_DATESTAMP := $(shell date +'%Y%m')
BOX_NAME := vagrant-archlinux-test-$(RELEASE_DATESTAMP)

build:
	packer build -var-file isovars.pkrvars.hcl archbox.pkr.hcl

# Build a bootable qcow2 disk image (no Vagrant/VirtualBox involved)
build-qemu:
	packer build -var-file isovars.pkrvars.hcl archbox-qemu.pkr.hcl

# Boot the newest qcow2 image straight in this terminal (serial console)
run-qemu:
	./run-qemu.sh

clean:
	rm -f archlinux-x64-*.box

clean-qemu:
	rm -rf output-archlinux-qemu

init:
	packer init .

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
