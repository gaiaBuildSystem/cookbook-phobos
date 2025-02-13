#!/bin/bash

# Get the environment variables
ARCH=${ARCH}
MACHINE=${MACHINE}
BUILD_PATH=${BUILD_PATH}
USER_PASSWD=${USER_PASSWD}
USER=${USER}
PSWD=${PSWD}
USER_LOGIN_USER=${USER_LOGIN_USER}
INITRAMFS_PATH=${INITRAMFS_PATH}
DISTRO_MAJOR=${DISTRO_MAJOR}
DISTRO_MINOR=${DISTRO_MINOR}
DISTRO_PATCH=${DISTRO_PATCH}

IMAGE_MNT_BOOT="${BUILD_PATH}/tmp/${MACHINE}/mnt/boot"
IMAGE_MNT_ROOT="${BUILD_PATH}/tmp/${MACHINE}/mnt/root"

# Get the actual script path
SCRIPT_PATH=$(dirname $(realpath $0))

echo "Create the .img for the ostree based distro"

# Check if the .img file exists
IMG_OTA_PATH="${BUILD_PATH}/tmp/${MACHINE}/deploy/${MACHINE}-ota-${DISTRO_MAJOR}-${DISTRO_MINOR}-${DISTRO_PATCH}.img"

if [ -f "${IMG_OTA_PATH}" ]; then
    rm -rf "${IMG_OTA_PATH}"
fi

OS_TREE_DEPLOY_PATH="${BUILD_PATH}/tmp/${MACHINE}/ostree/deploy"

# Create the .img based on the distro .img
cp "${BUILD_PATH}/tmp/${MACHINE}/deploy/${MACHINE}-${DISTRO_MAJOR}-${DISTRO_MINOR}-${DISTRO_PATCH}.img" "${IMG_OTA_PATH}"

# create the mapping
kpartxret="$(kpartx -av $IMG_OTA_PATH)"
read PART_LOOP <<<$(grep -o 'loop.' <<<"$kpartxret")

# mount it
mkdir -p $IMAGE_MNT_BOOT-ota
mkdir -p $IMAGE_MNT_ROOT-ota

mount /dev/mapper/${PART_LOOP}p1 $IMAGE_MNT_BOOT-ota
mount /dev/mapper/${PART_LOOP}p2 $IMAGE_MNT_ROOT-ota

# clean the rootfs
rm -rf ${IMAGE_MNT_ROOT}-ota/*

# debug if the rootfs was really cleaned
echo "-----------------------------------------------------------------Rootfs cleaned:"
ls -la ${IMAGE_MNT_ROOT}-ota/
echo "-----------------------------------------------------------------Rootfs cleaned:"

# clone from the ostree
rsync -a ${OS_TREE_DEPLOY_PATH}/ ${IMAGE_MNT_ROOT}-ota/

# debug if the rootfs was really cloned
echo "-----------------------------------------------------------------Rootfs cloned:"
ls -la ${IMAGE_MNT_ROOT}-ota/
ls -la ${IMAGE_MNT_ROOT}-ota/ostree/repo
ls -la ${IMAGE_MNT_ROOT}-ota/ostree/repo/refs
echo "-----------------------------------------------------------------Rootfs cloned:"

# unmount the partitions
umount $IMAGE_MNT_BOOT-ota
umount $IMAGE_MNT_ROOT-ota

# remove the mapping
kpartx -dv $IMG_OTA_PATH

echo "OTA .img created"
