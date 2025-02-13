#!/bin/bash

set -e

_path=$(dirname "$0")

# go to the target rootfs because we need the binaries in the right architecture
echo $USER_PASSWD | sudo -E -S chroot $IMAGE_MNT_ROOT /bin/bash -c "
    apt-get install -y python3-pip python3 &&
    cd / &&
    pip3 install --break-system-packages setuptools &&
    pip3 install --break-system-packages wheel scons &&
    pip3 install --break-system-packages staticx &&
    apt-get download ostree-boot &&
    dpkg-deb -x ostree-boot*.deb /tmp/ostree-boot &&
    staticx /tmp/ostree-boot/usr/lib/ostree/ostree-prepare-root ostree-prepare-root
"

# copy the static binaries to the initramfs folder
echo $USER_PASSWD | sudo -E -S mv $IMAGE_MNT_ROOT/ostree-prepare-root $INITRAMFS_PATH/bin/ostree-prepare-root

# deploy the mount root script
echo $USER_PASSWD | sudo -E -S cp $_path/busybox/90-root.sh $INITRAMFS_PATH/scripts/90-root.sh

# clean the target rootfs
echo ${USER_PASSWD} | sudo -E -S chroot $IMAGE_MNT_ROOT /bin/bash -c "
    pip3 uninstall --break-system-packages -y setuptools &&
    pip3 uninstall --break-system-packages -y staticx &&
    pip3 uninstall --break-system-packages -y wheel scons &&
    apt-get purge -y python3-pip python3 &&
    rm /ostree-boot*.deb &&
    rm -rf /tmp/ostree-boot
"
