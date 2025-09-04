#!/bin/busybox sh

echo "[initramfs] initializing video splash screen..."

echo "[initramfs] modeset initializing..."
/usr/mplayer-splash/mplayer -nosound -vo fbdev2 /usr/mplayer-splash/1.mp4 >/dev/null 2>&1
echo "[initramfs] splash initialized..."
/usr/mplayer-splash/mplayer -loop 0 -nosound -vo fbdev2 /usr/mplayer-splash/2.mp4 >/dev/null 2>&1 &
echo "[initramfs] splash loop..."
