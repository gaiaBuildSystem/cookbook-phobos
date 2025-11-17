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
    "Deploying microhobby telemetry ...",
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


# deploy the gaia-info
cp @(_path)/files/gaia-info @(_IMAGE_MNT_ROOT)/usr/bin/gaia-info
chmod +x @(_IMAGE_MNT_ROOT)/usr/bin/gaia-info

# deploy the telemetry
cp @(_path)/files/telemetry @(_IMAGE_MNT_ROOT)/usr/sbin/telemetry
chmod +x @(_IMAGE_MNT_ROOT)/usr/sbin/telemetry

# deploy the systemd service
cp @(_path)/files/microhobby-telemetry.service @(_IMAGE_MNT_ROOT)/etc/systemd/system/microhobby-telemetry.service

# enable it
sudo chroot @(_IMAGE_MNT_ROOT) systemctl enable microhobby-telemetry.service


print(
    "Deploying microhobby telemetry, ok",
    color=Color.WHITE,
    bg_color=BgColor.GREEN
)
