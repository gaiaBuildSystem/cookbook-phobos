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

_IMAGE_MNT_BOOT = f"{_BUILD_PATH}/tmp/{_MACHINE}/mnt/boot-ota"
_IMAGE_MNT_ROOT = f"{_BUILD_PATH}/tmp/{_MACHINE}/mnt/root-ota"
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
# Add significant padding: 150% extra space + minimum 500MB for filesystem overhead
_PADDING_MB = max(int(_ROOTFS_SIZE_MB * 1.5), 500)
_TOTAL_SIZE_MB = _ROOTFS_SIZE_MB + _PADDING_MB

print(f"Rootfs content size: {_ROOTFS_SIZE_MB}MB, padding: {_PADDING_MB}MB, total: {_TOTAL_SIZE_MB}MB", color=Color.WHITE, bg_color=BgColor.BLUE)

# create the rootfs image file
_ROOTFS_IMG = f"{_DEPLOY_DIR}/ota-rootfs.img"
sudo dd if=/dev/zero of=@(_ROOTFS_IMG) bs=1M count=@(_TOTAL_SIZE_MB) status=progress

# format as ext4 with more inodes and reserved space
sudo mkfs.ext4 -F -m 1 -N 500000 @(_ROOTFS_IMG)
sudo e2label @(_ROOTFS_IMG) "rootfs"

# mount the image to copy rootfs content
_TEMP_MNT = f"{_BUILD_PATH}/tmp/{_MACHINE}/mnt/temp_ota_rootfs"
sudo mkdir -p @(_TEMP_MNT)

# Attach the image to a free loop device and mount that device.
# Using losetup --find --show is safer in concurrent environments than
# relying on the mount implementation to pick a free loop device.
_LOOP_DEV = $(sudo losetup --find --show @(_ROOTFS_IMG))
# strip any trailing newline from the captured output
_LOOP_DEV = _LOOP_DEV.strip()
sudo mount @(_LOOP_DEV) @(_TEMP_MNT)

try:
    # copy rootfs content excluding virtual filesystems
    print("Copying rootfs content to image (excluding virtual filesystems)...", color=Color.WHITE, bg_color=BgColor.BLUE)
    sudo rsync -aHS \
        --exclude=/proc \
        --exclude=/sys \
        --exclude=/dev \
        --exclude=/run \
        --exclude=/tmp \
        --exclude=/lost+found \
        @(f"{_IMAGE_MNT_ROOT}/") @(f"{_TEMP_MNT}/")

    sync  # ensure all data is written
    print("Rootfs image created successfully", color=Color.WHITE, bg_color=BgColor.BLUE)

except Exception as e:
    print("syna-tools preparing emmc partitions, OOPS...", color=Color.WHITE, bg_color=BgColor.RED)
    print(e)
finally:
    # always unmount
    sudo umount @(_TEMP_MNT) || true
    sudo rmdir @(_TEMP_MNT) || true

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


# create the eMMCimg folder
# the eMMMimg should be already there
# we need to remove the old rootfs files
sudo rm -rf @(_DEPLOY_DIR)/eMMCimg/rootfs.subimg.*
# overwrite the partition data
sudo cp @(_path)/eMMCimg/* @(_DEPLOY_DIR)/eMMCimg/

# copy the files that was wrote to the metadata
_splitted_rootfs = []
with open(f"{_DEPLOY_DIR}/metadata_rootfs.txt", "r") as f:
    for line in f:
        file = line.strip()
        _file_replaced = file.replace('ota-rootfs', 'rootfs')
        _file_absolute = os.path.join(_DEPLOY_DIR, file)

        if os.path.isfile(_file_absolute):
            sudo mv @(_file_absolute) @(_DEPLOY_DIR)/eMMCimg/@(_file_replaced)
            _splitted_rootfs.append(_file_replaced)
        else:
            print(f"Warning: File {file} listed in metadata does not exist.", color=Color.WHITE, bg_color=BgColor.RED)


# replace the emmc_part_list.template with the actual rootfs size
with open(f"{_path}/eMMCimg/emmc_part_list.template", 'r') as file:
    _filedata = file.read()
    _filedata = _filedata.replace('{{ROOTFS_SIZE}}', str(_TOTAL_SIZE_MB))

# create the file and set the content
sudo touch @(f"{_DEPLOY_DIR}/eMMCimg/emmc_part_list")
# set the permission to open and write for all
sudo chmod 666 @(_DEPLOY_DIR)/eMMCimg/emmc_part_list
sudo chmod 666 @(_DEPLOY_DIR)/eMMCimg/emmc_image_list

with open(f"{_DEPLOY_DIR}/eMMCimg/emmc_part_list", 'w') as file:
    file.write(_filedata)

sudo rm -rf @(_DEPLOY_DIR)/eMMCimg/emmc_part_list.template

# also append on the emmc_image_list the rootfs files
with open(f"{_DEPLOY_DIR}/eMMCimg/emmc_image_list", 'a') as file:
    if len(_splitted_rootfs) == 0:
        print("Warning: No rootfs parts were created.", color=Color.YELLOW, bg_color=BgColor.RED)
    elif len(_splitted_rootfs) == 1:
        file.write("rootfs.subimg.gz,sd8\n")
    else:
        for part in _splitted_rootfs:
            file.write(f"{part},sd8\n")


# always remove the non compressed .img
sudo rm -rf @(_ROOTFS_IMG)


print("syna-tools preparing emmc partitions, OK", color=Color.WHITE, bg_color=BgColor.GREEN)
