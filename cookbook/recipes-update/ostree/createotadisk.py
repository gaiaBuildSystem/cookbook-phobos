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

print(f"Create the .img for the ostree based distro")

# run the createotadisk.sh script
_cmds = [
    f"{_path}/createotadisk.sh"
]

# _cmds = []

# # check if the .img file exists
# _img_ota_path = f"{BUILD_PATH}/tmp/{MACHINE}/deploy/{MACHINE}-ota-{DISTRO_MAJOR}-{DISTRO_MINOR}-{DISTRO_PATCH}.img"

# if os.path.exists(_img_ota_path):
#     _cmds += [
#         f"rm -rf {_img_ota_path}"
#     ]

# _os_tree_deploy_path = f"{BUILD_PATH}/tmp/{MACHINE}/ostree/deploy"

# _cmds += [
#     # create the .img based on the distro .img
#     f"cp {BUILD_PATH}/tmp/{MACHINE}/deploy/{MACHINE}-{DISTRO_MAJOR}-{DISTRO_MINOR}-{DISTRO_PATCH}.img {_img_ota_path}",

#     # mount it
#     f"mkdir -p {IMAGE_MNT_BOOT}-ota",
#     f"mkdir -p {IMAGE_MNT_ROOT}-ota",
#     f"mount -o loop {_img_ota_path} {IMAGE_MNT_BOOT}-ota",
#     f"mount -o loop {_img_ota_path} {IMAGE_MNT_ROOT}-ota",

#     # remove all from rootfs
#     f"rm -rf {IMAGE_MNT_ROOT}-ota/*",

#     # clone all from ostree to rootfs
#     f"rsync -a {_os_tree_deploy_path}/ {IMAGE_MNT_ROOT}-ota/",

#     # unmount it
#     f"umount {IMAGE_MNT_BOOT}-ota",
#     f"umount {IMAGE_MNT_ROOT}-ota"
# ]

for _cmd in _cmds:
    print(f"\033[94mRunning: {_cmd}\033[0m")

    subprocess.run(
        f"sudo -k -E -S "
        f"{_cmd}",
        shell=True,
        check=True,
        executable="/bin/bash",
        input=f"{USER_PASSWD}\n".encode(),
        env=os.environ
    )

print(f"OTA .img created")
