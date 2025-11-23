#!/bin/busybox sh

echo "[initramfs] initializing video splash screen..."

# copy it to the /dev/tmpfs
mkdir -p /dev/splash
mount -t tmpfs tmpfs /dev/splash
cp /usr/mplayer-splash/1.mp4 /dev/splash/1.mp4

# force set mode
/bin/drmset 0

# good to go
/usr/mplayer-splash/mplayer -nosound -vo drm -fixed-vo -loop 0 -loop-start 1.57 /dev/splash/1.mp4 >/dev/null 2>&1 &
echo "[initramfs] splash loop..."
