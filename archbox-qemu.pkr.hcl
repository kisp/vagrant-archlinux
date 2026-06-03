packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1"
    }
  }
}

variable "isochecksum_sha256" {
  type = string
}

variable "isourl" {
  type = string
}

# Optional build-time features (all off by default). Enable e.g. with
# `make build-qemu NIX=1` or `PKR_VAR_enable_nix=true packer build ...`.
variable "enable_nix" {
  type    = bool
  default = false
}

source "qemu" "archlinux" {
  iso_url      = var.isourl
  iso_checksum = "sha256:${var.isochecksum_sha256}"

  accelerator    = "kvm"
  headless       = true
  disk_size      = "51200M"
  format         = "qcow2"
  disk_interface = "virtio"
  net_device     = "virtio-net"
  memory         = 1024
  cpus           = 1

  ssh_username = "root"
  ssh_password = "toor"
  ssh_port     = 22
  ssh_timeout  = "10000s"

  # Unlike the VirtualBox build, partitioning is NOT done via keystrokes here
  # (interactive fdisk typed over VNC is unreliable under QEMU). We only set
  # the root password and start sshd; scripts/base.sh partitions the disk
  # itself over SSH (PARTITION=yes below).
  #
  # The waits must be long enough for the live ISO to reach its autologin
  # shell before these keys are typed, otherwise they are lost and sshd
  # never comes up (Packer then hangs on "Waiting for SSH").
  boot_wait    = "10s"
  boot_command = ["<enter>", "<wait10><wait10><wait10><wait10><wait10>", "echo root:toor | chpasswd<enter>", "<wait5>", "systemctl start sshd<enter>"]

  shutdown_command = "echo '/sbin/halt -h -p' > shutdown.sh; echo 'vagrant'|sudo -S bash 'shutdown.sh'"

  output_directory = "output-archlinux-qemu"
  vm_name          = "archlinux-x64-${formatdate("YYYYMM", timestamp())}.qcow2"
}

build {
  sources = ["source.qemu.archlinux"]

  provisioner "shell" {
    # Override the VirtualBox defaults baked into scripts/base.sh.
    environment_vars = [
      "DISK=/dev/vda",
      "PARTITION=yes",
      "GUEST_PKG=qemu-guest-agent",
      "GUEST_SERVICE=qemu-guest-agent",
      "EXTRA_GROUPS=adm,disk,wheel,log",
      "NET_MANAGER=dhcpcd",
      "ENABLE_NIX=${var.enable_nix ? "1" : ""}",
    ]
    scripts = [
      "scripts/base.sh",
      "scripts/features.sh",
      "scripts/vagrant.sh",
      "scripts/clean.sh"
    ]
  }
}
