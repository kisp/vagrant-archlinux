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
	vagrant box add mypacker archlinux-x64-$(RELEASE_DATESTAMP).box --force

remove-box:
	vagrant box remove mypacker

start-vm:
	vagrant up
	vagrant ssh

destroy-vm:
	vagrant destroy -f
