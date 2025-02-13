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

# Fucking aktualizr does not support docker compose v2
# so, we need to make some workaround
print(f"Setting docker-compose alias for aktualizr")

_cmds = [
    f"cp {_path}/files/docker-compose {IMAGE_MNT_ROOT}/usr/bin/docker-compose",
    f"chmod +x {IMAGE_MNT_ROOT}/usr/bin/docker-compose"
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

print(f"deploy docker-compose for aktualizr ok!")
