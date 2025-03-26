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

print(f"Installing easy-splash assets")

_cmds = []

# assets
_cmds += [
    f"mkdir -p {IMAGE_MNT_ROOT}/usr/easy-splash",
    f"cp {_path}/assets/part1.mp4 {IMAGE_MNT_ROOT}/usr/easy-splash/part1.mp4",
    f"cp {_path}/assets/animation.toml {IMAGE_MNT_ROOT}/usr/easy-splash/animation.toml",
    f"cp {BUILD_PATH}/tmp/{MACHINE}/EasySplash/target/debug/easysplash {IMAGE_MNT_ROOT}/usr/easy-splash/easysplash",
    f"cp {_path}/assets/easy-splash.service {IMAGE_MNT_ROOT}/etc/systemd/system/easy-splash.service",
    f"cp {_path}/assets/easy-splash-stop.service {IMAGE_MNT_ROOT}/etc/systemd/system/easy-splash-stop.service"
]

for _cmd in _cmds:
    print(f"\033[94mRunning: {_cmd}\033[0m")

    subprocess.run(
        f"sudo -k "
        f"{_cmd}",
        shell=True,
        check=True,
        executable="/bin/bash",
        input=f"{USER_PASSWD}\n".encode(),
        env=os.environ
    )

# enable the services
str_cmd = (
    f"sudo -k "
    f"chroot {IMAGE_MNT_ROOT} /bin/bash -c \""
    f"systemctl enable easy-splash-stop.service"
    f"\""
)

subprocess.run(
    str_cmd,
    shell=True,
    check=True,
    executable="/bin/bash",
    env=os.environ
)


print(f"deploy easy-splash ok!")
