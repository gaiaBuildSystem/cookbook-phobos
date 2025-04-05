#!/bin/bash

set -e

_path=$(dirname "$0")


cd /
apt-get download ostree-boot
dpkg-deb -x ostree-boot*.deb /tmp/ostree-boot
staticx /tmp/ostree-boot/usr/lib/ostree/ostree-prepare-root ostree-prepare-root

# copy the static binaries to the initramfs folder
mv /ostree-prepare-root $INITRAMFS_PATH/bin/ostree-prepare-root

# deploy the mount root script
cp $_path/busybox/90-root.sh $INITRAMFS_PATH/scripts/90-root.sh
