RELEASE_DATESTAMP := $(shell date +'%Y%m')

build:
	packer build -var-file isovars.pkrvars.hcl mybox.pkr.hcl

clean:
	rm -f archlinux-x64-*.box

init:
	packer init .

list-boxes:
	vagrant box list

add-box:
	vagrant box add vagrant-archlinux-test archlinux-x64-$(RELEASE_DATESTAMP).box --force

remove-box:
	vagrant box remove vagrant-archlinux-test

start-vm:
	vagrant up
	vagrant ssh

destroy-vm:
	vagrant destroy -f

upload:
	./upload.sh
