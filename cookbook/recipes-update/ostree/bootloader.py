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

print(f"Deploying bootloader specific assets ...")

_cmds = []

if ARCH == "linux/amd64":
    _cmds = [
        f"mkdir -p {IMAGE_MNT_ROOT}/usr/lib/ostree",
        f"cp {_path}/grub/ostree-grub-generator {IMAGE_MNT_ROOT}/usr/lib/ostree/ostree-grub-generator",
        f"chmod +x {IMAGE_MNT_ROOT}/usr/lib/ostree/ostree-grub-generator",
        f"mkdir -p {IMAGE_MNT_ROOT}/etc/ostree.d",
        f"cp {_path}/grub/99_fallback_logic {IMAGE_MNT_ROOT}/etc/ostree.d/99_fallback_logic"
    ]

for _cmd in _cmds:
    print(f"\033[94mRunning: {_cmd}\033[0m")

    subprocess.run(
        f"sudo -k "
        f"{_cmd}",
        shell=True,
        check=True,
        executable="/bin/bash",
        env=os.environ
    )

print(f"deploy for bootloader specific assets for ostree ok!")
