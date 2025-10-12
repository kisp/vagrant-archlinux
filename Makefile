RELEASE_DATESTAMP := $(shell date +'%Y%m')
BOX_NAME := vagrant-archlinux-test-$(RELEASE_DATESTAMP)

build:
	packer build -var-file isovars.pkrvars.hcl archbox.pkr.hcl

clean:
	rm -f archlinux-x64-*.box

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
