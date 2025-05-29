#!/usr/bin/python3

import os
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
DISTRO_MAJOR = os.getenv('DISTRO_MAJOR')
DISTRO_MINOR = os.getenv('DISTRO_MINOR')
DISTRO_PATCH = os.getenv('DISTRO_PATCH')

IMAGE_MNT_BOOT = f"{BUILD_PATH}/tmp/{MACHINE}/mnt/boot"
IMAGE_MNT_ROOT = f"{BUILD_PATH}/tmp/{MACHINE}/mnt/root"
os.environ['IMAGE_MNT_BOOT'] = IMAGE_MNT_BOOT
os.environ['IMAGE_MNT_ROOT'] = IMAGE_MNT_ROOT

# get the actual script path
_path = os.path.dirname(os.path.realpath(__file__))

print("Create the .img for the ostree based distro")

# run the createotadisk.sh script
_cmds = [
    f"{_path}/createotadisk.sh"
]

for _cmd in _cmds:
    print(f"\033[94mRunning: {_cmd}\033[0m")

    subprocess.run(
        f"sudo -k -E "
        f"{_cmd}",
        shell=True,
        check=True,
        executable="/bin/bash",
        env=os.environ
    )

print("OTA .img created")
