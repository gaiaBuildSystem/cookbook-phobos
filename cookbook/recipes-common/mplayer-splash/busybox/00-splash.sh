#!/bin/busybox sh

echo "[initramfs] initializing video splash screen..."

/bin/fbset -t 39721 48 16 33 10 96 2
/usr/mplayer-splash/mplayer -nosound -vo fbdev2 /usr/mplayer-splash/1.mp4 >/dev/null 2>&1
/usr/mplayer-splash/mplayer -loop 0 -nosound -vo fbdev2 /usr/mplayer-splash/2.mp4 >/dev/null 2>&1 &
