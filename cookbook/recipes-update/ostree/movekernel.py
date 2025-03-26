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

print(f"moving kernel to the /usr/lib/modules/$kver")

# install the kernel image on the boot partition
LINUX_IMAGE = "vmlinuz"
LINUX_ARCH = ARCH

if ARCH == "linux/arm64":
    LINUX_ARCH = "arm64"
    LINUX_IMAGE = "Image"
elif ARCH == "linux/amd64":
    LINUX_ARCH = "x86"
    LINUX_IMAGE = "bzImage"

os.environ['LINUX_ARCH'] = LINUX_ARCH

kernel_versions = os.listdir(f"{IMAGE_MNT_ROOT}/usr/lib/modules")

# Assume there is only one directory
if len(kernel_versions) != 1:
    raise Exception(
        "Expected exactly one kernel version directory in /usr/lib/modules"
    )

subprocess.run(
    f" \
        sudo -k \
        cp -a {IMAGE_MNT_BOOT}/{LINUX_IMAGE} {IMAGE_MNT_ROOT}/usr/lib/modules/{kernel_versions[0]}/vmlinuz \
    ",
    shell=True,
    check=True,
    executable="/bin/bash",
    input=f"{USER_PASSWD}\n".encode(),
    env=os.environ
)

print(f"kernel moved successfully!")
