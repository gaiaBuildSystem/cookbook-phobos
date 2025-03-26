#!/usr/bin/python3

import os
import shutil
import subprocess

# get the environment

ARCH = os.getenv('ARCH')
MACHINE = os.getenv('MACHINE')
BUILD_PATH = os.getenv('BUILD_PATH')
USER_PASSWD = os.getenv('USER_PASSWD')
USER = os.getenv('USER')
PSWD = os.getenv('PSWD')
USER_LOGIN_USER = os.getenv('USER_LOGIN_USER')
INITRAMFS_PATH = os.getenv('INITRAMFS_PATH')

IMAGE_MNT_BOOT = f"{BUILD_PATH}/tmp/{MACHINE}/mnt/boot"
IMAGE_MNT_ROOT = f"{BUILD_PATH}/tmp/{MACHINE}/mnt/root"
os.environ['IMAGE_MNT_BOOT'] = IMAGE_MNT_BOOT
os.environ['IMAGE_MNT_ROOT'] = IMAGE_MNT_ROOT

# get the actual script path
_path = os.path.dirname(os.path.realpath(__file__))

print(f"Adding TCCP debian source ...")

# copy the .list to the image
str_cmd1 = (
    f"sudo -k "
    f"cp {_path}/files/toradex.list {IMAGE_MNT_ROOT}/etc/apt/sources.list.d/"
)

# get the feed signing key
str_cmd = (
    f"sudo -k "
    f"chroot {IMAGE_MNT_ROOT} /bin/bash -c \""
    f"apt-get update && apt-get install -y gnupg2 curl && \
        curl -fsSL https://feeds.toradex.com/staging/debian/toradex-debian-repo-19092023.asc | gpg --dearmor > /usr/share/keyrings/toradex.gpg"
    f"\""
)

_cmds = [str_cmd1, str_cmd]

for cmd in _cmds:
    subprocess.run(
        cmd,
        shell=True,
        check=True,
        executable="/bin/bash",
        env=os.environ
    )

print(f"before package tccp-debian ok!")
