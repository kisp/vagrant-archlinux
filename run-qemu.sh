#!/bin/bash
#
# Boot a built Arch Linux qcow2 image directly in the current terminal.
#
# The image's GRUB/kernel are configured for a serial console (console=ttyS0),
# and systemd auto-starts a getty there, so with -nographic you watch Arch boot
# and get a login prompt right here in your shell. No GUI, no libvirt.
#
# Log in as:  vagrant / vagrant   (sudo via the wheel group)
# Quit QEMU:  Ctrl-a x            (Ctrl-a c switches to the QEMU monitor)
#
# Usage:
#   ./run-qemu.sh [image.qcow2]
#
# With no argument it boots the newest image in output-archlinux-qemu/.

set -euo pipefail

IMAGE="${1:-}"
MEM="${MEM:-1024}"

if [ -z "$IMAGE" ]; then
  IMAGE=$(ls -t output-archlinux-qemu/*.qcow2 2>/dev/null | head -n1 || true)
fi

if [ -z "$IMAGE" ] || [ ! -f "$IMAGE" ]; then
  echo "No qcow2 image found. Build one first (make build-qemu) or pass a path." >&2
  exit 1
fi

# Use hardware acceleration when available, otherwise fall back to emulation.
ACCEL=()
if [ -w /dev/kvm ]; then
  ACCEL=(-enable-kvm -cpu host)
else
  echo "Note: /dev/kvm not available, falling back to slow TCG emulation." >&2
fi

echo "Booting $IMAGE (Ctrl-a x to quit) ..." >&2
exec qemu-system-x86_64 \
  "${ACCEL[@]}" \
  -m "$MEM" \
  -drive file="$IMAGE",format=qcow2,if=virtio \
  -nic user,model=virtio \
  -nographic
