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
    "Fetching aktualizr to build garage tools ...",
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

# check if we already have the folder created
if not os.path.exists(f"{_BUILD_ROOT}/uptane-sign"):
    mkdir -p @(f"{_BUILD_ROOT}/uptane-sign")
else:
    rm -rf @(f"{_BUILD_ROOT}/uptane-sign/*")


# check if the file is already downloaded
if os.path.exists(f"{_BUILD_ROOT}/uptane-sign/{meta['file']}"):
    print(
        f"File [{meta['file']}] already downloaded, skipping",
        color=Color.WHITE,
        bg_color=BgColor.YELLOW
    )
    sys.exit(0)

os.chdir(f"{_BUILD_ROOT}/uptane-sign")
wget @(meta['source'])/@(meta['file'])

# the checksum match?
_wget_file_path = f"{_BUILD_ROOT}/uptane-sign/{meta['file']}"
_wget_file_checksum = $(sha256sum @(_wget_file_path) | awk '{print $1}')

# here I'm assuming that the checksum is for linux/amd64, as this is JVM app
# and should be the same for all platforms
if _wget_file_checksum != meta['checksum']['linux/amd64']:
    Error_Out(
        f"Checksum mismatch for [{meta['file']}], expected [{meta['checksum']['linux/amd64']}] got [{_wget_file_checksum}]",
        Error.EFAIL
    )

print(
    "Fetching aktualizr to build garage tools, OK",
    color=Color.WHITE,
    bg_color=BgColor.GREEN
)
