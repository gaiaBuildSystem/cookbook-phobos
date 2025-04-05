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

IMAGE_MNT_BOOT = f"{BUILD_PATH}/tmp/{MACHINE}/mnt/boot"
IMAGE_MNT_ROOT = f"{BUILD_PATH}/tmp/{MACHINE}/mnt/root"
os.environ['IMAGE_MNT_BOOT'] = IMAGE_MNT_BOOT
os.environ['IMAGE_MNT_ROOT'] = IMAGE_MNT_ROOT

# get the actual script path
_path = os.path.dirname(os.path.realpath(__file__))

print(f"Adding user {USER_LOGIN_USER} to the groups ...")

# add the user to the docker group
str_cmd = (
    f"sudo -k "
    f"chroot {IMAGE_MNT_ROOT} /bin/bash -c \""
    f"getent group docker > /dev/null && "
    f"usermod -aG docker {USER_LOGIN_USER} && "
    f"echo 'User {USER_LOGIN_USER} added to docker group' || "
    f"echo 'Docker group does not exist, skipping'"
    f"\""
)

subprocess.run(str_cmd, shell=True, check=True, executable="/bin/bash")

print(f"User {USER_LOGIN_USER} added to the groups successfully!")
