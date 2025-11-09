#!/bin/busybox sh

echo "[initramfs] initializing video splash screen..."

echo "[initramfs] modeset initializing..."
/usr/mplayer-splash/mplayer -nosound -vo drm /usr/mplayer-splash/1.mp4 >/dev/null 2>&1

# I hate to do this, but some screens need some time to proper show the first frame
sleep 1

echo "[initramfs] splash initialized..."
/usr/mplayer-splash/mplayer -loop 0 -nosound -vo drm /usr/mplayer-splash/2.mp4 >/dev/null 2>&1 &
echo "[initramfs] splash loop..."
