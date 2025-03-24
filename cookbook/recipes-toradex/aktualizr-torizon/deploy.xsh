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
    "Deploying aktualizr to target garage tools ...",
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
# we need super cow powers
echo @(_USER_PASSWD) | sudo -k -S \
    echo "🐮"

# deploy the .deb
sudo cp @(_BUILD_ROOT)/aktualizr-torizon/build/aktualizr.deb @(_IMAGE_MNT_ROOT)/tmp/
sudo cp @(_BUILD_ROOT)/aktualizr-torizon/build/garage_deploy.deb @(_IMAGE_MNT_ROOT)/tmp/

# install the deb
sudo chroot @(_IMAGE_MNT_ROOT) apt-get remove -y aktualizr-torizon
sudo chroot @(_IMAGE_MNT_ROOT) apt-get install -y /tmp/aktualizr.deb /tmp/garage_deploy.deb

# cleanup
sudo rm @(_IMAGE_MNT_ROOT)/tmp/*.deb

# config
sudo mkdir -p @(_IMAGE_MNT_ROOT)/etc/sota/conf.d
sudo cp @(_path)/files/20-sota-device-cred.toml @(_IMAGE_MNT_ROOT)/etc/sota/conf.d/
sudo cp @(_path)/files/30-rollback.toml @(_IMAGE_MNT_ROOT)/etc/sota/conf.d/
sudo cp @(_path)/files/40-hardware-id.toml @(_IMAGE_MNT_ROOT)/etc/sota/conf.d/
sudo cp @(_path)/files/50-secondaries.toml @(_IMAGE_MNT_ROOT)/etc/sota/conf.d/
sudo cp @(_path)/files/60-polling-interval.toml @(_IMAGE_MNT_ROOT)/etc/sota/conf.d/
sudo cp @(_path)/files/70-disable-ostree.toml @(_IMAGE_MNT_ROOT)/etc/sota/conf.d/
sudo cp @(_path)/files/80-offline-updates.toml @(_IMAGE_MNT_ROOT)/etc/sota/conf.d/
sudo cp @(_path)/files/90-force-reboot.toml @(_IMAGE_MNT_ROOT)/etc/sota/conf.d/
sudo cp @(_path)/files/gateway.url @(_IMAGE_MNT_ROOT)/etc/sota/
sudo cp @(_path)/files/root.crt @(_IMAGE_MNT_ROOT)/etc/sota/
sudo cp @(_path)/files/secondaries.json @(_IMAGE_MNT_ROOT)/etc/sota/
sudo rm -rf @(_IMAGE_MNT_ROOT)/usr/lib/sota

# systemd
sudo cp @(_path)/files/aktualizr-torizon.service @(_IMAGE_MNT_ROOT)/lib/systemd/system/
# enable it on the chroot
sudo chroot @(_IMAGE_MNT_ROOT) systemctl enable aktualizr-torizon.service


print(
    "Deploying aktualizr to target garage tools, ok",
    color=Color.WHITE,
    bg_color=BgColor.GREEN
)
