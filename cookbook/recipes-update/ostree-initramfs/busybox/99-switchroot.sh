#!/bin/busybox sh

echo "[initramfs] switching to ostree deploy..."

/bin/ostree-prepare-root /mnt/root
exec switch_root /mnt/root /sbin/init
