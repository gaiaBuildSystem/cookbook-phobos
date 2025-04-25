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
DISTRO_BUILD = os.getenv('DISTRO_BUILD')

IMAGE_MNT_BOOT = f"{BUILD_PATH}/tmp/{MACHINE}/mnt/boot"
IMAGE_MNT_ROOT = f"{BUILD_PATH}/tmp/{MACHINE}/mnt/root"
os.environ['IMAGE_MNT_BOOT'] = IMAGE_MNT_BOOT
os.environ['IMAGE_MNT_ROOT'] = IMAGE_MNT_ROOT

OS_RELEASE_VERSION = f"{DISTRO_MAJOR}.{DISTRO_MINOR}.{DISTRO_PATCH}.{DISTRO_BUILD}"
os.environ['OS_RELEASE_VERSION'] = OS_RELEASE_VERSION

# get the actual script path
_path = os.path.dirname(os.path.realpath(__file__))

print("Setting up the rootfs for ostree")

_cmds = []

# FIXME: we need to add a way to maintain new builds
# if the CLEAN_IMAGE is "true" we need to also remove ostree
# if os.getenv('CLEAN_IMAGE') == "true":
#     # check if the folder exists
if os.path.exists(f"{BUILD_PATH}/tmp/{MACHINE}/ostree"):
    print("Removing ostree")
    _cmds += [
        f"bash -c 'chattr -R -i {BUILD_PATH}/tmp/{MACHINE}/ostree | true'",
        f"rm -rf {BUILD_PATH}/tmp/{MACHINE}/ostree"
    ]

# first create the ostree repo
_os_tree_cloned_rootfs = f"{BUILD_PATH}/tmp/{MACHINE}/ostree/cloned"
_os_tree_sysroot_path = f"{BUILD_PATH}/tmp/{MACHINE}/ostree/sysroot"
_os_tree_deploy_path = f"{BUILD_PATH}/tmp/{MACHINE}/ostree/deploy"
# _os_tree_repo_path = f"{BUILD_PATH}/tmp/{MACHINE}/ostree/repo"
_os_tree_repo_path = f"{_os_tree_deploy_path}/ostree/repo"

_cmds += [
    # create the folders
    f"mkdir -p {_os_tree_cloned_rootfs}",
    f"mkdir -p {_os_tree_deploy_path}",
    f"mkdir -p {_os_tree_cloned_rootfs}/sysroot",
    f"mkdir -p {_os_tree_sysroot_path}/var/rootdirs",

    # clone the persistent ones to sysroot/var/rootdirs
    f"rsync -a {IMAGE_MNT_ROOT}/opt/ {_os_tree_sysroot_path}/var/rootdirs/opt/",
    f"rsync -a {IMAGE_MNT_ROOT}/mnt/ {_os_tree_sysroot_path}/var/rootdirs/mnt/",
    f"rsync -a {IMAGE_MNT_ROOT}/media/ {_os_tree_sysroot_path}/var/rootdirs/media/",
    f"rsync -a {IMAGE_MNT_ROOT}/srv/ {_os_tree_sysroot_path}/var/rootdirs/srv/",
    f"rsync -a {IMAGE_MNT_ROOT}/var/ {_os_tree_sysroot_path}/var/rootdirs/var/",
    f"rsync -a {IMAGE_MNT_ROOT}/root/ {_os_tree_sysroot_path}/var/rootdirs/root/",
    f"rsync -a {IMAGE_MNT_ROOT}/home/ {_os_tree_sysroot_path}/var/rootdirs/home/",
    f"rsync -a {IMAGE_MNT_ROOT}/etc/ {_os_tree_sysroot_path}/etc/",

    # clone all the folders from rootfs, less the kernel created ones
    f"rsync -a \
        --exclude=/etc \
        --exclude=/proc \
        --exclude=/sys \
        --exclude=/dev \
        --exclude=/run \
        --exclude=/boot \
        --exclude=/lost+found \
        --exclude=/tmp \
        --exclude=/var \
        --exclude=/opt \
        --exclude=/mnt \
        --exclude=/media \
        --exclude=/srv \
        --exclude=/root \
        --exclude=/home \
        {IMAGE_MNT_ROOT}/ \
        {_os_tree_cloned_rootfs}/",

    # make the link between /var/rootdirs and the respective folders
    f"ln -sf sysroot/ostree/deploy/phobos/var/rootdirs/opt {_os_tree_cloned_rootfs}/opt",
    f"ln -sf sysroot/ostree/deploy/phobos/var/rootdirs/mnt {_os_tree_cloned_rootfs}/mnt",
    f"ln -sf sysroot/ostree/deploy/phobos/var/rootdirs/media {_os_tree_cloned_rootfs}/media",
    f"ln -sf sysroot/ostree/deploy/phobos/var/rootdirs/srv {_os_tree_cloned_rootfs}/srv",
    f"ln -sf sysroot/ostree/deploy/phobos/var/rootdirs/var {_os_tree_cloned_rootfs}/var",
    f"ln -sf sysroot/ostree/deploy/phobos/var/rootdirs/root {_os_tree_cloned_rootfs}/root",
    f"ln -sf sysroot/ostree/deploy/phobos/var/rootdirs/home {_os_tree_cloned_rootfs}/home",
    f"ln -sf sysroot/ostree {_os_tree_cloned_rootfs}/ostree",
    f"ln -sf sysroot/boot {_os_tree_cloned_rootfs}/boot",
    f"mkdir -p {_os_tree_cloned_rootfs}/dev",
    f"mkdir -p {_os_tree_cloned_rootfs}/proc",
    f"mkdir -p {_os_tree_cloned_rootfs}/sys",
    f"mkdir -p {_os_tree_cloned_rootfs}/run",
    f"mkdir -p {_os_tree_cloned_rootfs}/tmp",

    # move the etc to /usr/etc
    f"mv {_os_tree_sysroot_path}/etc {_os_tree_cloned_rootfs}/usr/etc"
    # "mkdir -p {_os_tree_cloned_rootfs}/usr/etc",
]

# FIXME: we need to add a way to maintain new builds
_cmds += [
    # prepare the ostree rootfs
    f"ostree --sysroot={_os_tree_deploy_path} admin init-fs --modern {_os_tree_deploy_path}",
    f"ostree --sysroot={_os_tree_deploy_path} admin os-init phobos",
    f"mkdir -p {_os_tree_deploy_path}/boot/loader.0",
    f"ln -sf loader.0 {_os_tree_deploy_path}/boot/loader"
]

if ARCH == "linux/amd64":
    # for x86_64 we use grub
    # so, we need to inject variables to ostree know
    os.environ['OSTREE_BOOT_PARTITION'] = "/boot"
    os.environ['OSTREE_GRUB2_EXEC'] = f"{IMAGE_MNT_ROOT}/usr/lib/ostree/ostree-grub-generator"

    _cmds += [
        f"cp {BUILD_PATH}/tmp/{MACHINE}/grub/grub.cfg {_os_tree_deploy_path}/boot/loader.0/grub.cfg",
        f"mkdir -p {_os_tree_deploy_path}/boot/grub2",
        f"ln -sf ../loader/grub.cfg {_os_tree_deploy_path}/boot/grub2/grub.cfg"
    ]

if ARCH == "linux/arm64":
    # for aarch64 we use u-boot
    _cmds += [
        f"touch {_os_tree_deploy_path}/boot/loader/uEnv.txt",
        f"ln -s loader/uEnv.txt {_os_tree_deploy_path}/boot/uEnv.txt"
    ]

# ostree commit
_cmds += [
    f"ostree --repo={_os_tree_repo_path} commit \
        --branch {MACHINE} \
        --tree=dir={_os_tree_cloned_rootfs} \
        --add-metadata-string=\"version={OS_RELEASE_VERSION}\" \
        --add-metadata-string=\"gaia.arch={ARCH}\" \
        --add-metadata-string=\"gaia.machine={MACHINE}\" \
    "
]

# now we can deploy the default ostree commit
_cmds += [
    f"ostree --sysroot={_os_tree_deploy_path} admin deploy --os=phobos {MACHINE}",
    f"ostree --repo={_os_tree_repo_path} summary -u"
]

# and finally, we can move the /var/rootdirs to the deploy var
_cmds += [
    f"mv {_os_tree_sysroot_path}/var/rootdirs {_os_tree_deploy_path}/ostree/deploy/phobos/var/rootdirs"
]

for _cmd in _cmds:
    print(f"\033[94mRunning: {_cmd}\033[0m")

    subprocess.run(
        f"sudo -k -E "
        f"{_cmd}",
        shell=True,
        check=True,
        executable="/bin/bash",
        input=f"{USER_PASSWD}\n".encode(),
        env=os.environ
    )

print("os-tree fixup ok!")
