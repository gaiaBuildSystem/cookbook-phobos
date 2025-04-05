#!/usr/bin/env xonsh

# Copyright (c) 2025 MicroHobby
# SPDX-License-Identifier: MIT

# use the xonsh environment to update the OS environment
$UPDATE_OS_ENVIRON = True
# always return if a cmd fails
$RAISE_SUBPROC_ERROR = True

import os
import sys
import json
import os.path
from torizon_templates_utils.colors import print,BgColor,Color
from torizon_templates_utils.errors import Error_Out,Error


print(
    "Cleaning up OTA image ...",
    color=Color.WHITE,
    bg_color=BgColor.GREEN
)

# get the common variables
_ARCH = os.environ.get('ARCH')
_MACHINE = os.environ.get('MACHINE')
_MAX_IMG_SIZE = os.environ.get('MAX_IMG_SIZE')
_BUILD_PATH = os.environ.get('BUILD_PATH')
_DISTRO_MAJOR = os.environ.get('DISTRO_MAJOR')
_DISTRO_MINOR = os.environ.get('DISTRO_MINOR')
_DISTRO_PATCH = os.environ.get('DISTRO_PATCH')
_DISTRO_BUILD = os.environ.get('DISTRO_BUILD')
_DISTRO_CODENAME = os.environ.get('DISTRO_CODENAME')
_USER_PASSWD = os.environ.get('USER_PASSWD')

# read the meta data
meta = json.loads(os.environ.get('META', '{}'))

# get the actual script path, not the process.cwd
_path = os.path.dirname(os.path.abspath(__file__))

_IMAGE_MNT_BOOT = f"{_BUILD_PATH}/tmp/{_MACHINE}/mnt/boot"
_IMAGE_MNT_ROOT = f"{_BUILD_PATH}/tmp/{_MACHINE}/mnt/root"
_IMAGE_OTA_PATH = f"{_BUILD_PATH}/tmp/{_MACHINE}/deploy/{_MACHINE}-ota-{_DISTRO_MAJOR}-{_DISTRO_MINOR}-{_DISTRO_PATCH}.img"
_OSTREE_REPO_PATH = f"{_BUILD_PATH}/tmp/{_MACHINE}/ostree/deploy/ostree/repo"
_OSTREE_REPO_Z2_PATH = f"{_BUILD_PATH}/tmp/{_MACHINE}/ostree/deploy/ostree/repo.z2"
_TUF_REPO = f"{_BUILD_PATH}/tmp/{_MACHINE}/tuf"
os.environ['IMAGE_MNT_BOOT'] = _IMAGE_MNT_BOOT
os.environ['IMAGE_MNT_ROOT'] = _IMAGE_MNT_ROOT

# detach the .img from /dev
sudo -k \
    echo "detaching ..."


$RAISE_SUBPROC_ERROR = False
sudo umount @(f"{_IMAGE_MNT_BOOT}-ota")
sudo umount @(f"{_IMAGE_MNT_ROOT}-ota")
$RAISE_SUBPROC_ERROR = True


# check if the image file exists
if not os.path.exists(_IMAGE_OTA_PATH):
    print(
        f"OTA image file {_IMAGE_OTA_PATH} does not exist, skipping the cleanup",
        color=Color.WHITE,
        bg_color=BgColor.YELLOW
    )
    sys.exit(0)


sleep 1
sudo kpartx -dv @(_IMAGE_OTA_PATH)
sleep 1

_LOOP_DEVICE = $(losetup -j @(_IMAGE_OTA_PATH) | awk -F: '{print $1}')
if not _LOOP_DEVICE:
    print(
        f"Error: no loop device found for {_IMAGE_OTA_PATH}, skipping the cleanup",
        color=Color.WHITE,
        bg_color=BgColor.YELLOW
    )
    sys.exit(0)

# remove the loop device
sudo losetup -d @(_LOOP_DEVICE)

# remove any /dev/mapper entry
if os.path.exists("/dev/mapper"):
    for _dev in os.listdir("/dev/mapper"):
        if _dev.startswith("loop"):
            print(f"Removing /dev/mapper/{_dev} ...")
            try:
                sudo dmsetup remove @(_dev)
            except Exception as e:
                print(
                    f"Error removing /dev/mapper/{_dev}: {e}",
                    color=Color.WHITE,
                    bg_color=BgColor.YELLOW
                )


print(
    "Cleaning up OTA image, OK",
    color=Color.WHITE,
    bg_color=BgColor.GREEN
)
