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
# With no argument it uses the newest base image in images/ (overlays, which
# live in the same directory, are skipped). Environment variables:
#   IMAGES_DIR=dir directory holding the qcow2 images (default: images)
#   OVERLAY=path   where to keep the writable overlay (default: images/<base>.overlay.qcow2)
#   RESET=1        discard any existing overlay and start from a fresh one
#   NO_OVERLAY=1   boot the base image directly (writes persist into it)
#   MEM=2048       guest memory in MB (default 8192)
#   CPUS=2         number of virtual CPUs (default 4)
#   GUI=1          open a graphical QEMU window (gtk) and keep serial on stdout;
#                  use this for X11/StumpWM testing (requires display on the host)
#   VNC=1          expose the guest display via QEMU's built-in VNC server on
#                  port 5901 and keep serial on stdout; connect remotely with:
#                    ssh -L 5901:localhost:5901 <host>
#                  then point any VNC client at localhost:5901

set -euo pipefail

BASE="${1:-}"
MEM="${MEM:-8192}"
CPUS="${CPUS:-4}"
IMAGES_DIR="${IMAGES_DIR:-images}"

if [ -z "$BASE" ]; then
  # Newest base image in IMAGES_DIR, skipping overlays (which also live here).
  BASE=$(ls -t "$IMAGES_DIR"/*.qcow2 2>/dev/null | grep -v '\.overlay\.qcow2$' | head -n1 || true)
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
  # The overlay sits next to its base (in IMAGES_DIR), so the images directory
  # holds only qcow2 files.
  BASE_ABS=$(realpath "$BASE")
  OVERLAY="${OVERLAY:-${BASE%.qcow2}.overlay.qcow2}"

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

if [ -n "${GUI:-}" ]; then
  DISPLAY_ARGS=(-display gtk -serial stdio)
elif [ -n "${VNC:-}" ]; then
  VNC_DISPLAY="${VNC_DISPLAY:-1}"
  VNC_PORT=$((5900 + VNC_DISPLAY))
  echo "VNC listening on port ${VNC_PORT} (display :${VNC_DISPLAY})" >&2
  echo "  Tunnel:  ssh -L ${VNC_PORT}:localhost:${VNC_PORT} $(hostname)" >&2
  echo "  Connect: vnc://localhost:${VNC_PORT}" >&2
  DISPLAY_ARGS=(-display vnc=:${VNC_DISPLAY} -serial stdio)
else
  echo "(Ctrl-a x to quit)" >&2
  DISPLAY_ARGS=(-nographic)
fi

exec qemu-system-x86_64 \
  "${ACCEL[@]}" \
  -m "$MEM" \
  -smp "$CPUS" \
  -drive file="$DISK",format=qcow2,if=virtio \
  -nic user,model=virtio,hostfwd=tcp::2222-:22 \
  "${DISPLAY_ARGS[@]}"
