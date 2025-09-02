#!/usr/bin/env xonsh

# Copyright (c) 2025 MicroHobby
# SPDX-License-Identifier: MIT

# use the xonsh environment to update the OS environment
$UPDATE_OS_ENVIRON = True
# always return if a cmd fails
$RAISE_SUBPROC_ERROR = True


import os
import json
import os.path
from torizon_templates_utils.colors import print,BgColor,Color
from torizon_templates_utils.errors import Error_Out,Error


print("syna-tools preparing emmc partitions ...", color=Color.WHITE, bg_color=BgColor.GREEN)

# get the common variables
_ARCH = os.environ.get('ARCH')
_MACHINE = os.environ.get('MACHINE')
_MAX_IMG_SIZE = os.environ.get('MAX_IMG_SIZE')
_BUILD_PATH = os.environ.get('BUILD_PATH')
_DISTRO_MAJOR = os.environ.get('DISTRO_MAJOR')
_DISTRO_MINOR = os.environ.get('DISTRO_MINOR')
_DISTRO_PATCH = os.environ.get('DISTRO_PATCH')
_USER_PASSWD = os.environ.get('USER_PASSWD')

# read the meta data
meta = json.loads(os.environ.get('META', '{}'))

# get the actual script path, not the process.cwd
_path = os.path.dirname(os.path.abspath(__file__))

_IMAGE_MNT_BOOT = f"{_BUILD_PATH}/tmp/{_MACHINE}/mnt/boot"
_IMAGE_MNT_ROOT = f"{_BUILD_PATH}/tmp/{_MACHINE}/mnt/root"
_DEPLOY_DIR = f"{_BUILD_PATH}/tmp/{_MACHINE}/deploy"
os.environ['IMAGE_MNT_BOOT'] = _IMAGE_MNT_BOOT
os.environ['IMAGE_MNT_ROOT'] = _IMAGE_MNT_ROOT
_REPO_PATH = f"{_BUILD_PATH}/tmp/{_MACHINE}/syna-tools"
_EXECUTABLES_PATH = f"{_REPO_PATH}/tools/src/executables"
_EMMC_PT_PATH = f"{_BUILD_PATH}/tmp/{_MACHINE}/syna-configs/product/sl1680_poky_aarch64_rdk/emmc.pt"

# make sure that the deploy dir is created
sudo mkdir -p @(_DEPLOY_DIR)

# first we need to create the rootfs.subimg.gz
# calculate the size of the rootfs directory (in KB), excluding virtual filesystems
print("Calculating rootfs size (excluding virtual filesystems)...", color=Color.WHITE, bg_color=BgColor.BLUE)
_ROOTFS_SIZE_KB = $(sudo du -sk --exclude=proc --exclude=sys --exclude=dev --exclude=run --exclude=tmp @(_IMAGE_MNT_ROOT) | cut -f1)
_ROOTFS_SIZE_MB = int(int(_ROOTFS_SIZE_KB) / 1024)
# Add significant padding: 50% extra space + minimum 500MB for filesystem overhead
_PADDING_MB = max(int(_ROOTFS_SIZE_MB * 0.5), 500)
_TOTAL_SIZE_MB = _ROOTFS_SIZE_MB + _PADDING_MB

print(f"Rootfs content size: {_ROOTFS_SIZE_MB}MB, padding: {_PADDING_MB}MB, total: {_TOTAL_SIZE_MB}MB", color=Color.WHITE, bg_color=BgColor.BLUE)

# create the rootfs image file
_ROOTFS_IMG = f"{_DEPLOY_DIR}/{_MACHINE}-ota-{_DISTRO_MAJOR}-{_DISTRO_MINOR}-{_DISTRO_PATCH}.img"
sudo dd if=/dev/zero of=@(_ROOTFS_IMG) bs=1M count=@(_TOTAL_SIZE_MB) status=progress

# format as ext4 with more inodes and reserved space
sudo mkfs.ext4 -F -m 1 -N 500000 @(_ROOTFS_IMG)
sudo e2label @(_ROOTFS_IMG) "rootfs"

# mount the image to copy rootfs content
_TEMP_MNT = f"{_BUILD_PATH}/tmp/{_MACHINE}/mnt/temp_ota_rootfs"
sudo mkdir -p @(_TEMP_MNT)
sudo mount -o loop @(_ROOTFS_IMG) @(_TEMP_MNT)

try:
    # copy rootfs content excluding virtual filesystems
    print("Copying rootfs content to image (excluding virtual filesystems)...", color=Color.WHITE, bg_color=BgColor.BLUE)
    sudo rsync -av \
        --exclude=/proc \
        --exclude=/sys \
        --exclude=/dev \
        --exclude=/run \
        --exclude=/tmp \
        --exclude=/lost+found \
        @(f"{_IMAGE_MNT_ROOT}/") @(f"{_TEMP_MNT}/")

    # create essential empty directories in the new rootfs
    sudo mkdir -p @(f"{_TEMP_MNT}/proc")
    sudo mkdir -p @(f"{_TEMP_MNT}/sys")
    sudo mkdir -p @(f"{_TEMP_MNT}/dev")
    sudo mkdir -p @(f"{_TEMP_MNT}/run")
    sudo mkdir -p @(f"{_TEMP_MNT}/tmp")

    # set proper permissions
    sudo chmod 1777 @(f"{_TEMP_MNT}/tmp")
    sudo chmod 755 @(f"{_TEMP_MNT}/proc") @(f"{_TEMP_MNT}/sys") @(f"{_TEMP_MNT}/dev") @(f"{_TEMP_MNT}/run")

    sync  # ensure all data is written
    print("Rootfs image created successfully", color=Color.WHITE, bg_color=BgColor.BLUE)

except Exception as e:
    print("syna-tools preparing emmc partitions, OOPS...", color=Color.WHITE, bg_color=BgColor.RED)
    print(e)
finally:
    # always unmount
    sudo umount @(_TEMP_MNT) || true
    sudo rmdir @(_TEMP_MNT) || true
    # check the disk for potential errors and fix it automatically
    # use the image file directly instead of loop device
    sudo fsck.ext4 -y -f -v @(_ROOTFS_IMG)

# optionally compress the image
_ROOTFS_IMG_GZ = f"{_ROOTFS_IMG}.gz"
print("Compressing rootfs image...", color=Color.WHITE, bg_color=BgColor.BLUE)
_cmd = f"gzip -fc {_ROOTFS_IMG} > {_ROOTFS_IMG_GZ}"
sudo bash -c @(f"{_cmd}")

print(f"Raw rootfs image created: {_ROOTFS_IMG}", color=Color.WHITE, bg_color=BgColor.BLUE)
print(f"Compressed rootfs image created: {_ROOTFS_IMG_GZ}", color=Color.WHITE, bg_color=BgColor.BLUE)

# now we need to split the image
# the syna bootloader only support 300mb by file
sudo \
    bash @(_path)/split.sh \
        @(_ROOTFS_IMG) \
        @(_ROOTFS_IMG_GZ) \
        300 \
        @(_DEPLOY_DIR)


# always remove the non compressed .img
sudo rm -rf @(_ROOTFS_IMG)


print("syna-tools preparing emmc partitions, OK", color=Color.WHITE, bg_color=BgColor.GREEN)
