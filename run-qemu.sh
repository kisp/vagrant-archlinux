#!/usr/bin/env bash
#
# Boot a built Arch Linux qcow2 image in the current terminal.
#
# The image's GRUB/kernel are configured for a serial console (console=ttyS0),
# and systemd auto-starts a getty there, so with -nographic you watch Arch boot
# and get a login prompt right here in your shell. No GUI, no libvirt.
#
# By default this does NOT boot the built image directly. It creates a qcow2
# OVERLAY backed by the built image and boots that, so the built image stays
# pristine and all your changes (installed packages, edited files, ...) land in
# the overlay. Delete the overlay (or run with RESET=1) to start fresh.
#
# Log in as:  vagrant / vagrant   (sudo via the wheel group)
# Quit QEMU:  Ctrl-a x            (Ctrl-a c switches to the QEMU monitor)
#
# Usage:
#   ./run-qemu.sh [base-image.qcow2]
#
# With no argument it uses the newest image in output-archlinux-qemu/ as the
# base. Environment variables:
#   OVERLAY=path   where to keep the writable overlay (default: ./<base>.overlay.qcow2)
#   RESET=1        discard any existing overlay and start from a fresh one
#   NO_OVERLAY=1   boot the base image directly (writes persist into it)
#   MEM=2048       guest memory in MB (default 1024)

set -euo pipefail

BASE="${1:-}"
MEM="${MEM:-1024}"

if [ -z "$BASE" ]; then
  BASE=$(ls -t output-archlinux-qemu/*.qcow2 2>/dev/null | head -n1 || true)
fi

if [ -z "$BASE" ] || [ ! -f "$BASE" ]; then
  echo "No qcow2 image found. Build one first (make build-qemu) or pass a path." >&2
  exit 1
fi

if [ -n "${NO_OVERLAY:-}" ]; then
  DISK="$BASE"
  echo "Booting base image directly (writes persist): $DISK" >&2
else
  # Keep the built base image pristine; boot a writable overlay backed by it.
  BASE_ABS=$(realpath "$BASE")
  OVERLAY="${OVERLAY:-$(basename "${BASE%.qcow2}").overlay.qcow2}"

  if [ -n "${RESET:-}" ]; then
    rm -f "$OVERLAY"
  fi

  if [ ! -f "$OVERLAY" ]; then
    echo "Creating overlay $OVERLAY (backed by $BASE_ABS) ..." >&2
    qemu-img create -f qcow2 -b "$BASE_ABS" -F qcow2 "$OVERLAY" >/dev/null
  fi

  DISK="$OVERLAY"
  echo "Booting overlay: $DISK (base $BASE_ABS stays untouched)" >&2
fi

# Use hardware acceleration when available, otherwise fall back to emulation.
ACCEL=()
if [ -w /dev/kvm ]; then
  ACCEL=(-enable-kvm -cpu host)
else
  echo "Note: /dev/kvm not available, falling back to slow TCG emulation." >&2
fi

echo "(Ctrl-a x to quit)" >&2
exec qemu-system-x86_64 \
  "${ACCEL[@]}" \
  -m "$MEM" \
  -drive file="$DISK",format=qcow2,if=virtio \
  -nic user,model=virtio \
  -nographic
