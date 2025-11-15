#!/bin/busybox sh

echo "[initramfs] initializing video splash screen..."

/usr/mplayer-splash/mplayer -nosound -vo drm -fixed-vo -loop 0 -loop-start 1.57 /sysroot/splash/1.mp4 >/dev/null 2>&1 &
echo "[initramfs] splash loop..."
