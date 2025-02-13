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

print(f"Installing .service for ostree")

subprocess.run(
    f"echo {USER_PASSWD} | sudo -k -S \
    cp {_path}/ostree-booted.service {IMAGE_MNT_ROOT}/etc/systemd/system/ostree-booted.service \
    ",
    shell=True,
    check=True,
    executable="/bin/bash",
    env=os.environ
)

# install the aktualizr debian packages to the image
str_cmd = (
    f"echo {USER_PASSWD} | sudo -k -S "
    f"chroot {IMAGE_MNT_ROOT} /bin/bash -c \""
    f"systemctl enable ostree-booted.service"
    f"\""
)

subprocess.run(
    str_cmd,
    shell=True,
    check=True,
    executable="/bin/bash",
    env=os.environ
)

print(f"deploy ostree service ok!")
