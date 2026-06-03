# vagrant-archlinux
Arch Linux x86_64 base box

## Vagrant Cloud

This box is available at
https://app.vagrantup.com/kisp/boxes/archlinux

The new home for the box is
https://portal.cloud.hashicorp.com/services/vagrant/registries/kisp/boxes/archlinux?project_id=45aa27c5-4428-4a7c-b5ed-cefb713e8459

## QEMU disk image

Besides the Vagrant/VirtualBox box, you can build a plain bootable qcow2 disk
image and run it directly in your terminal — no Vagrant, no libvirt, no GUI.

```sh
make init        # once, to install the qemu Packer plugin
make build-qemu  # produces output-archlinux-qemu/archlinux-x64-YYYYMM.qcow2
make run-qemu    # boots the newest image in this terminal (serial console)
```

`run-qemu.sh` boots with `-nographic`, so you watch Arch boot and get a login
prompt right in your shell. Log in as `vagrant` / `vagrant` (passwordless sudo
via the `wheel` group). Press `Ctrl-a x` to quit QEMU.

To keep the built image pristine, `run-qemu.sh` boots a writable qcow2 *overlay*
backed by it (`<image>.overlay.qcow2`); all your changes land in the overlay.
Start fresh with `RESET=1 make run-qemu`, or boot the base directly with
`NO_OVERLAY=1 make run-qemu`. `make clean-qemu` removes the image and overlays.

The image is built from the same provisioning scripts as the box; the QEMU build
(`archbox-qemu.pkr.hcl`) just overrides a few `scripts/base.sh` parameters
(virtio `/dev/vda`, `qemu-guest-agent`, `dhcpcd`) via Packer environment
variables.
