# vagrant-archlinux
Arch Linux x86_64 base box

## Build environment (Nix)

A `flake.nix` provides all the build tooling (Packer, QEMU, jq, make) pinned via
Nix, so you don't have to install anything system-wide:

```sh
nix develop          # drops you in a shell with packer + qemu on PATH
make init
make build-qemu      # or: make build
```

Convenience runners are also exposed (run from the repo root):

```sh
nix run .#build-qemu
nix run .#run-qemu
nix run .#build
```

What Nix pins here is the **tooling**, not the produced image. The image build
still boots a VM and `pacstrap`s the *latest* Arch packages from mirrors at build
time, so it needs `/dev/kvm` + network and is **not** a hermetic/bit-reproducible
Nix derivation — that's why this is a dev shell rather than a `nix build`. Also:
`make init` still fetches Packer plugins over the network, and the VirtualBox
build expects your **system** VirtualBox (running VirtualBox from Nix on a
non-NixOS host needs matching kernel modules and is not handled here).

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

## Optional build-time features

Both builds support optional features that are **off by default** and can be
switched on at build time. They're implemented in `scripts/features.sh` and
exposed as Packer `enable_<feature>` variables.

- **Nix** — installs the `nix` package, enables the multi-user daemon, turns on
  flakes (`experimental-features = nix-command flakes`), and adds the `vagrant`
  user to the `nix-users` group:

  ```sh
  make build-qemu NIX=1        # or: make build NIX=1
  # equivalently: PKR_VAR_enable_nix=true packer build ... <template>
  ```

Adding more features (e.g. `sbcl` + quicklisp) follows the same pattern; see the
header comment in `scripts/features.sh`.
