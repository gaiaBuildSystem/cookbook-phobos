#!/bin/busybox sh

echo "[initramfs] copying splash media to switch root..."

mkdir -p /sysroot/splash
cp /usr/mplayer-splash/1.mp4 /sysroot/splash/1.mp4
