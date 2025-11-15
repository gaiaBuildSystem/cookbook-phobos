#!/bin/busybox sh

echo "[initramfs] copying splash media to switch root..."

mkdir -p /sysroot/usr/mplayer-splash
cp /usr/mplayer-splash/1.mp4 /sysroot/usr/mplayer-splash/1.mp4
