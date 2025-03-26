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

print(f"configuring dpkg ...")

_cmds = []

if os.path.exists(f"{IMAGE_MNT_ROOT}/usr/var/lib/apt") == False:
    _cmds += [
        f"mkdir -p {IMAGE_MNT_ROOT}/usr/var/lib",
        f"mkdir -p {IMAGE_MNT_ROOT}/usr/var/cache",
        f"mv {IMAGE_MNT_ROOT}/var/lib/apt {IMAGE_MNT_ROOT}/usr/var/lib/apt",
        f"mv {IMAGE_MNT_ROOT}/var/lib/dpkg {IMAGE_MNT_ROOT}/usr/var/lib/dpkg",
        f"mv {IMAGE_MNT_ROOT}/var/cache/apt {IMAGE_MNT_ROOT}/usr/var/cache/apt",
    ]

_cmds += [
    f"mkdir -p {IMAGE_MNT_ROOT}/etc/dpkg",
    f"cp {_path}/files/dpkg.cfg {IMAGE_MNT_ROOT}/etc/dpkg/dpkg.cfg",
    f"mkdir -p {IMAGE_MNT_ROOT}/etc/apt",
    f"cp {_path}/files/apt.conf {IMAGE_MNT_ROOT}/etc/apt/apt.conf",
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

print(f"dpkg config ok!")
