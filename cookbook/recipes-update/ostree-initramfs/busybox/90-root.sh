#!/bin/busybox sh

if [[ $root == LABEL:* ]]; then
    _label="${root#*:}"
    echo "[initramfs] searching for root partition with label $_label"

    # Wait for the device to be available
    timeout=30 # Timeout in seconds
    interval=1 # Interval between checks in seconds
    elapsed=0

    while [ -z "$_dev" ]; do
        sleep $interval
        _dev=$(findfs LABEL=$_label)
        elapsed=$((elapsed + interval))

        if [ $elapsed -ge $timeout ]; then
            echo "[initramfs] root device find timeout"
            exit 69
        fi
    done

    echo "[initramfs] root partition label $_label found at $_dev"

    # clean the symlink for the mplayer
    rm -rf /sysroot
    mkdir -p /sysroot
    mount -t ext4 $_dev /sysroot

    echo "[initramfs] root partition $root mounted"

else
    echo "[initramfs] root partition argument not found"
    exit 69
fi
