build:
	packer build -var-file isovars.pkrvars.hcl mybox.pkr.hcl

init:
	packer init .

list-boxes:
	vagrant box list

add-box:
	vagrant box add mypacker archlinux-x64-202309.box --force

remove-box:
	vagrant box remove mypacker

start-box:
	vagrant up
	vagrant ssh
