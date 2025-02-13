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

print(f"Setting the custom hardware id for aktualizr")

template_file_path = os.path.join(_path, 'files', '40-hardware-id.toml.template')
ret_file_path = os.path.join(
    BUILD_PATH,
    "tmp",
    MACHINE,
    'aktualizr',
    '40-hardware-id.toml'
)

# make sure that the path exists
os.makedirs(os.path.dirname(ret_file_path), exist_ok=True)

with open(template_file_path, 'r') as file:
    file_contents = file.read()

file_contents = file_contents.replace(
    '{{AKTUALIZR_PRIMARY_ECU_HARDWARE_ID}}',
    f"torizon-debian-{MACHINE}"
)

with open(ret_file_path, 'w') as file:
    file.write(file_contents)

subprocess.run(
    f"echo {USER_PASSWD} | sudo -k -S "
    f"cp {ret_file_path} {IMAGE_MNT_ROOT}/etc/sota/conf.d/40-hardware-id.toml",
    shell=True,
    check=True,
    cwd=f"{BUILD_PATH}/tmp/{MACHINE}/aktualizr",
    executable="/bin/bash",
    env=os.environ
)

print(f"deploy aktualizr ok!")
