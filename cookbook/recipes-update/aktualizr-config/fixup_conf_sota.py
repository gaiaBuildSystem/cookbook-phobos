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

IMAGE_MNT_BOOT = f"{BUILD_PATH}/tmp/{MACHINE}/mnt/boot"
IMAGE_MNT_ROOT = f"{BUILD_PATH}/tmp/{MACHINE}/mnt/root"
os.environ['IMAGE_MNT_BOOT'] = IMAGE_MNT_BOOT
os.environ['IMAGE_MNT_ROOT'] = IMAGE_MNT_ROOT

# get the actual script path
_path = os.path.dirname(os.path.realpath(__file__))

print("Setup conf ostree aktualizr ...")


_cmds = [
    f"rm -rf {IMAGE_MNT_ROOT}/etc/sota/conf.d/70-disable-ostree.toml",
    f"cp -f {_path}/files/70-enable-ostree.toml {IMAGE_MNT_ROOT}/etc/sota/conf.d/",
    f"cp -f {_path}/files/71-complete-update.toml {IMAGE_MNT_ROOT}/etc/sota/conf.d/",
    f"mkdir -p {IMAGE_MNT_ROOT}/usr/share/sota",
    f"cp -f {_path}/files/sotaComplete.sh {IMAGE_MNT_ROOT}/usr/bin/sotaComplete.sh",
    f"chmod +x {IMAGE_MNT_ROOT}/usr/bin/sotaComplete.sh",
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


print("Setup conf ostree aktualizr, OK")
