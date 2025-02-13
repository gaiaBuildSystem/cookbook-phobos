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

print(f"checking if we need to wrapp the ostree for x86_64")

if ARCH == "linux/amd64":
    print("wrapping ostree for x86_64")

    if os.path.exists(f"{IMAGE_MNT_ROOT}/usr/bin/ostree-bin") == False:
        _cmds = [
            # copy the ostree binary
            f"cp -a {IMAGE_MNT_ROOT}/usr/bin/ostree {IMAGE_MNT_ROOT}/usr/bin/ostree-bin",

            # deploy the wrapper
            f"cp {_path}/files/ostree {IMAGE_MNT_ROOT}/usr/bin/ostree",
            f"chmod +x {IMAGE_MNT_ROOT}/usr/bin/ostree"
        ]

        for _cmd in _cmds:
            print(f"\033[94mRunning: {_cmd}\033[0m")

            subprocess.run(
                f"echo {USER_PASSWD} | sudo -k -S "
                f"{_cmd}",
                shell=True,
                check=True,
                executable="/bin/bash",
                env=os.environ
            )

print(f"ostree wrapper ok!")
