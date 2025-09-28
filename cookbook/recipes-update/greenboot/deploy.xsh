#!/usr/bin/env xonsh

# Copyright (c) 2025 MicroHobby
# SPDX-License-Identifier: MIT

# use the xonsh environment to update the OS environment
$UPDATE_OS_ENVIRON = True
# always return if a cmd fails
$RAISE_SUBPROC_ERROR = True
$XONSH_SHOW_TRACEBACK = True

import os
import json
import os.path
from torizon_templates_utils.colors import print,BgColor,Color
from torizon_templates_utils.errors import Error_Out,Error


print(
    "Deploying greenboot ...",
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
_USER_PASSWD = os.environ.get('USER_PASSWD')

# read the meta data
meta = json.loads(os.environ.get('META', '{}'))

# get the actual script path, not the process.cwd
_path = os.path.dirname(os.path.abspath(__file__))

_IMAGE_MNT_BOOT = f"{_BUILD_PATH}/tmp/{_MACHINE}/mnt/boot"
_IMAGE_MNT_ROOT = f"{_BUILD_PATH}/tmp/{_MACHINE}/mnt/root"
_BUILD_ROOT = f"{_BUILD_PATH}/tmp/{_MACHINE}"
os.environ['IMAGE_MNT_BOOT'] = _IMAGE_MNT_BOOT
os.environ['IMAGE_MNT_ROOT'] = _IMAGE_MNT_ROOT
$BUILD_ROOT = _BUILD_ROOT


# deploy the files
# sync the greenboot/usr with the root/usr
sudo \
    rsync -a \
    @(f"{_BUILD_ROOT}/greenboot/usr/") @(f"{_IMAGE_MNT_ROOT}/usr/")


sudo \
    rsync -a \
    @(f"{_BUILD_ROOT}/greenboot/etc/") @(f"{_IMAGE_MNT_ROOT}/etc/")

sudo \
    install -d @(f"{_IMAGE_MNT_ROOT}/etc/greenboot/green.d")

sudo \
    install -d @(f"{_IMAGE_MNT_ROOT}/etc/greenboot/red.d")

sudo \
    install -d @(f"{_IMAGE_MNT_ROOT}/etc/greenboot/check/required.d")

sudo \
    install -d @(f"{_IMAGE_MNT_ROOT}/etc/greenboot/check/wanted.d")

sudo \
    install -m 755 \
    @(f"{_path}/files/00_cleanup_uboot_vars.sh") \
    @(f"{_IMAGE_MNT_ROOT}/etc/greenboot/green.d")
sudo \
    install -m 755 \
    @(f"{_path}/files/01_log_rollback_info.sh") \
    @(f"{_IMAGE_MNT_ROOT}/etc/greenboot/green.d")
sudo \
    install -m 755 \
    @(f"{_path}/files/greenboot-status") \
    @(f"{_IMAGE_MNT_ROOT}/usr/libexec/greenboot")
sudo \
    install -m 755 \
    @(f"{_path}/files/greenboot-logs") \
    @(f"{_IMAGE_MNT_ROOT}/usr/libexec/greenboot")
sudo \
    install -m 644 \
    @(f"{_path}/files/redboot-auto-reboot") \
    @(f"{_IMAGE_MNT_ROOT}/usr/libexec/greenboot")

# enable the service
sudo chroot @(_IMAGE_MNT_ROOT) systemctl enable greenboot-healthcheck.service
sudo chroot @(_IMAGE_MNT_ROOT) systemctl enable greenboot-status.service


print(
    "Deploying greenboot, ok",
    color=Color.WHITE,
    bg_color=BgColor.GREEN
)
