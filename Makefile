init:
	packer init .

build:
	packer build -var-file isovars.pkrvars.hcl mybox.pkr.hcl
