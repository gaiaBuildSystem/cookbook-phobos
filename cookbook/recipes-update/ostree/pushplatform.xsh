#!/usr/bin/env xonsh

# Copyright (c) 2025 MicroHobby
# SPDX-License-Identifier: MIT

import os
import sys
import json
import os.path
from torizon_templates_utils.colors import print,BgColor,Color
from torizon_templates_utils.errors import Error_Out,Error


print(
    "Preparing to push OTA to Torizon Cloud ...",
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
_OSTREE_REPO_PATH = f"{_BUILD_PATH}/tmp/{_MACHINE}/ostree/deploy/ostree/repo"
_OSTREE_REPO_Z2_PATH = f"{_BUILD_PATH}/tmp/{_MACHINE}/ostree/deploy/ostree/repo.z2"
_TUF_REPO = f"{_BUILD_PATH}/tmp/{_MACHINE}/tuf"
os.environ['IMAGE_MNT_BOOT'] = _IMAGE_MNT_BOOT
os.environ['IMAGE_MNT_ROOT'] = _IMAGE_MNT_ROOT

# check if we have the env OSTREE_GARAGE_PUSH
if 'OSTREE_GARAGE_PUSH' not in os.environ or os.environ['OSTREE_GARAGE_PUSH'] != 'true':
    print(
        "OSTREE_GARAGE_PUSH is not set to true, skipping the push to Torizon Cloud",
        color=Color.WHITE,
        bg_color=BgColor.YELLOW
    )
    sys.exit(0)


# Let's make a mess in the garage

_commit = $(ostree --repo=@(_OSTREE_REPO_PATH) rev-parse @(_MACHINE))
_module = _MACHINE
_credentials_path = f"{_path}/credentials/credentials.zip"
_package_name = f"{_module}"
_version = f"phobos-{_DISTRO_MAJOR}.{_DISTRO_MINOR}.{_DISTRO_PATCH}.{_DISTRO_BUILD}"
_codename = f"{_DISTRO_CODENAME}"

# check if the credentials file exists
if not os.path.exists(_credentials_path):
    Error_Out(
        f"Credentials file not found: {_credentials_path}\n" +
        "If the purpose of your build does not mean to send the OTA to the Torizon Cloud set OSTREE_GARAGE_PUSH to false on the recipe JSON",
        Error.ENOFOUND
    )

# we need to convert the bare repo to archive-z2
print(
    "Converting the OSTree repository to archive-z2 format ...",
    color=Color.WHITE,
    bg_color=BgColor.BLUE
)


if not os.path.exists(_OSTREE_REPO_Z2_PATH):
    print("Creating the OSTree z2 folder ...")
    echo @(_USER_PASSWD) | sudo -k -S \
        mkdir -p @(_OSTREE_REPO_Z2_PATH)

    print("Initializing the OSTree z2 repository ...")
    echo @(_USER_PASSWD) | sudo -k -S \
        ostree init --repo=@(_OSTREE_REPO_Z2_PATH) --mode=archive-z2

print("Sync OSTree repository to archive-z2 format ...")
echo @(_USER_PASSWD) | sudo -k -S \
    ostree -v --repo=@(_OSTREE_REPO_Z2_PATH) pull-local @(_OSTREE_REPO_PATH) @(_MACHINE)


print(
f"""
Pushing OTA to Torizon Cloud
    - Module: {_module}
    - Commit: {_commit}
    - Version: {_version}
""",
    color=Color.WHITE,
    bg_color=BgColor.BLUE
)

garage-push \
    --credentials @(_credentials_path) \
    --repo @(_OSTREE_REPO_Z2_PATH) \
    --ref @(_commit)
    #--loglevel 4

print(
f"""
Signing OTA to Torizon Cloud
    - Module: {_module}
    - Commit: {_commit}
    - Package: {_package_name}
    - Version: {_version}
""",
    color=Color.WHITE,
    bg_color=BgColor.BLUE
)

print("prepare metadata ...")
_meta = {
    "commitBody": "",
    "commitSubject": f"{_module}-{_commit}-{_codename}-{_version}",
    "ostreeMetadata": {
        "gaia.arch": _ARCH,
        "gaia.distro": "phobos",
        "gaia.distro-codename": "lion-killer",
        "gaia.image": "phobos-ota",
        "gaia.machine": _MACHINE,
        "gaia.build-purpose": "development",
        "gaia.debian-major": "12",
        "ostree.ref.binding": [
            f"{_module}"
        ],
        "version": f"{_version}-{_codename}"
    }
}

_meta_json = json.dumps(_meta)

print("init ...")
uptane-sign \
    init \
    --credentials @(_credentials_path) \
    --repo @(_TUF_REPO) \
    --verbose

print("targets pull ...")
uptane-sign \
    targets \
    pull \
    --repo @(_TUF_REPO) \
    --verbose

print("targets add ...")
uptane-sign \
    targets \
    add \
    --repo @(_TUF_REPO) \
    --name @(_package_name) \
    --format OSTREE \
    --version @(_version) \
    --length 0 \
    --sha256 @(_commit) \
    --hardwareids @(_module) \
    --customMeta @(_meta_json) \
    --verbose

print("targets sign ...")
uptane-sign \
    targets \
    sign \
    --repo @(_TUF_REPO) \
    --key-name targets \
    --verbose

print("targets push ...")
uptane-sign \
    targets \
    push \
    --repo @(_TUF_REPO) \
    --verbose


print(
    "Preparing to push OTA to Torizon Cloud, OK",
    color=Color.WHITE,
    bg_color=BgColor.GREEN
)
