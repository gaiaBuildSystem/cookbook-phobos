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

print(f"overwriting the init script in the initramfs")

# copy the local init.sh to the initramfs
subprocess.run(
    f"echo {USER_PASSWD} | sudo -k -S cp {_path}/init.sh {INITRAMFS_PATH}/init",
    shell=True,
    check=True,
    executable="/bin/bash",
    env=os.environ
)

# Make the init script executable
subprocess.run(
    f"echo {USER_PASSWD} | sudo -k -S chmod +x {INITRAMFS_PATH}/init",
    shell=True,
    check=True,
    executable="/bin/bash",
    env=os.environ
)

print(f"init script overwritten successfully!")
