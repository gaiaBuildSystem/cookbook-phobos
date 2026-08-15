#!/usr/bin/env xonsh

# Copyright (c) 2026 MicroHobby
# SPDX-License-Identifier: MIT

# use the xonsh environment to update the OS environment
$UPDATE_OS_ENVIRON = True
# always return if a cmd fails
$XONSH_SUBPROC_CMD_RAISE_ERROR = True
$XONSH_SHOW_TRACEBACK = True

import os
import json
import glob
import os.path
from torizon_templates_utils.colors import print,BgColor,Color
from torizon_templates_utils.errors import Error_Out,Error


print(
    "Deploying device tree updates ...",
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

# spec for the json update that will be used by the complete update script
_json = {
    "update_type": "device-tree",
    "update_version": "1.0.0"
}

# the update version depends by machine
_machines = {
    "cm4": "1.0.1",
    "cm5": "1.0.0",
    "luna": "1.0.0",
    "rpi5": "1.0.0",
    "intel": "1.0.0",
    "rpi4b": "1.0.0",
    "rpi5b": "1.0.0",
    "qemuarm64": "1.0.0",
    "wsl-amd64": "1.0.0",
    "wsl-arm64": "1.0.0",
    "imx93-frdm": "1.0.0",
    "qemux86-64": "1.0.0",
    "smarc-imx95": "1.0.0",
    "astra-sl1680": "1.0.0",
    "astra-sl2619": "1.0.0",
    "arduino-uno-q": "1.0.0",
    "imx8mp-verdin": "1.0.0",
    "imx95-verdin-evk": "1.0.0"
}

# make sure that the /usr/share/sota folder exists
sudo mkdir -p @(_IMAGE_MNT_ROOT)/usr/share/sota

# create the device-tree.json file in the /usr/share/sota folder
_tmp_json = f"{_BUILD_ROOT}/sota-device-tree/device-tree.json"
# make sure that the sota-device-tree folder exists
mkdir -p @(_BUILD_ROOT)/sota-device-tree

_json["update_version"] = _machines.get(_MACHINE, "1.0.0")
with open(_tmp_json, "w") as f:
    json.dump(_json, f, indent=4)

sudo install -m 0644 @(_tmp_json) @(_IMAGE_MNT_ROOT)/usr/share/sota/device-tree.json
rm -f @(_tmp_json)

# some boards do not have a /boot folder, and some have a /boot folder
# but no .dtb files. Both cases must be skipped gracefully.
if not os.path.exists(f"{_IMAGE_MNT_BOOT}"):
    print(
        "No /boot folder found, skipping device tree deployment",
        color=Color.WHITE,
        bg_color=BgColor.YELLOW
    )

    exit(0)

_boot_dtb_files = glob.glob(f"{_IMAGE_MNT_BOOT}/*.dtb")
if not _boot_dtb_files:
    print(
        "No .dtb files found in /boot, skipping device tree deployment",
        color=Color.WHITE,
        bg_color=BgColor.YELLOW
    )

    exit(0)

# move all the .dtb from /boot to the /usr/share/sota
sudo cp -f @(_IMAGE_MNT_BOOT)/*.dtb @(_IMAGE_MNT_ROOT)/usr/share/sota/

print(
    "Deploying device tree updates, ok",
    color=Color.WHITE,
    bg_color=BgColor.GREEN
)
