#!/bin/busybox sh

echo "[initramfs] initializing video splash screen..."

# choose drm card based on machine map; env overrides
machine_id="${MACHINE:-unknown}"
case "${machine_id}" in
	rpi5b) card_id=1 ;;
	luna) card_id=1 ;;
	*) card_id=0 ;;
esac


# copy it to the /dev/tmpfs
mkdir -p /dev/splash
mount -t tmpfs tmpfs /dev/splash
cp /usr/mplayer-splash/1.mp4 /dev/splash/1.mp4

# force set mode
/bin/drmset ${card_id}

# good to go
/usr/mplayer-splash/mplayer -nosound -vo drm:/dev/dri/card${card_id} -fixed-vo -loop 0 -loop-start 1.57 /dev/splash/1.mp4 >/dev/null 2>&1 &
echo "[initramfs] splash loop..."
