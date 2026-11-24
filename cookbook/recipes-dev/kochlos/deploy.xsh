#!/usr/bin/env xonsh

# Copyright (c) 2025 MicroHobby
# SPDX-License-Identifier: MIT

# use the xonsh environment to update the OS environment
$UPDATE_OS_ENVIRON = True
# always return if a cmd fails
$XONSH_SUBPROC_CMD_RAISE_ERROR = True
$XONSH_SHOW_TRACEBACK = True

import os
import json
import os.path
from torizon_templates_utils.colors import print,BgColor,Color
from torizon_templates_utils.errors import Error_Out,Error


print(
    "Deploying kochlos binary ...",
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


# deploy the kochlos binary
sudo cp $BUILD_ROOT/kochlos/kochlos @(_IMAGE_MNT_ROOT)/usr/bin/kochlos
sudo chmod 755 @(_IMAGE_MNT_ROOT)/usr/bin/kochlos

# register it as a valid login shell
sudo chroot @(_IMAGE_MNT_ROOT) /bin/bash -c "grep -qxF /usr/bin/kochlos /etc/shells || echo /usr/bin/kochlos >> /etc/shells"

# set it as the default shell for root and the login user
_LOGIN_USER = os.environ.get('USER_LOGIN_USER', 'phobos')
for _user in ["root", _LOGIN_USER]:
    sudo chroot @(_IMAGE_MNT_ROOT) usermod -s /usr/bin/kochlos @(_user)

# the Torizon agent: checks the pairing as root and gives the shell (any user)
# access to the Torizon AI service through /run/kochlos/torizon.sock
sudo cp @(_path)/systemd/kochlos-torizon.service @(_IMAGE_MNT_ROOT)/etc/systemd/system/kochlos-torizon.service
sudo chroot @(_IMAGE_MNT_ROOT) systemctl enable kochlos-torizon.service

print(
    "Deploying kochlos binary, ok",
    color=Color.WHITE,
    bg_color=BgColor.GREEN
)
