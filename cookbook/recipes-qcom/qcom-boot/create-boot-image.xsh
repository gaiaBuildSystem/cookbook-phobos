#!/usr/bin/env xonsh

# Copyright (c) 2025 MicroHobby
# SPDX-License-Identifier: MIT

# use the xonsh environment to update the OS environment
$UPDATE_OS_ENVIRON = True
# always return if a cmd fails
$RAISE_SUBPROC_ERROR = True


import os
import json
import os.path
from torizon_templates_utils.colors import print,BgColor,Color
from torizon_templates_utils.errors import Error_Out,Error


print("Creating qcom boot.img ...", color=Color.WHITE, bg_color=BgColor.GREEN)

# get the common variables
_ARCH = os.environ.get('ARCH')
_MACHINE = os.environ.get('MACHINE')
_MAX_IMG_SIZE = os.environ.get('MAX_IMG_SIZE')
_BUILD_PATH = os.environ.get('BUILD_PATH')
_DISTRO_NAME = os.environ.get('DISTRO_NAME')
_DISTRO_MAJOR = os.environ.get('DISTRO_MAJOR')
_DISTRO_MINOR = os.environ.get('DISTRO_MINOR')
_DISTRO_PATCH = os.environ.get('DISTRO_PATCH')
_USER_PASSWD = os.environ.get('USER_PASSWD')
_IMAGE_NAME = os.environ.get('IMAGE_NAME')

# read the meta data
meta = json.loads(os.environ.get('META', '{}'))

# get the actual script path, not the process.cwd
_path = os.path.dirname(os.path.abspath(__file__))


# we are on PhobOS
# For PhobOS we need to use the ota image
# which is in fact the same partition layout but with another name
_IMAGE_NAME = f"{_DISTRO_NAME}-{_MACHINE}-ota-{_DISTRO_MAJOR}-{_DISTRO_MINOR}-{_DISTRO_PATCH}.img"


_QCOM_PTOOL_PATH = f"{_BUILD_PATH}/tmp/{_MACHINE}/qcom-ptool"
_DEPLOY_DIR = f"{_BUILD_PATH}/tmp/{_MACHINE}/deploy"
os.environ['DEPLOY_DIR'] = _DEPLOY_DIR


if os.environ["MACHINE"] == "arduino-uno-q":
    # .1 create the boot.img
    # zip the u-boot binary
    cd @(_BUILD_PATH)/tmp/@(_MACHINE)/u-boot/
    rm -rf u-boot-nodtb.bin.gz
    rm -rf u-boot-dtb.bin.gz
    gzip -k u-boot-nodtb.bin
    cat u-boot-nodtb.bin.gz ../linux/arch/arm64/boot/dts/qcom/qrb2210-arduino-imola.dtb > u-boot-dtb.bin.gz

    sudo mkbootimg \
        --base 0x80000000 \
        --pagesize 4096 \
        --kernel u-boot-dtb.bin.gz \
        --cmdline "root=/dev/notreal" \
        --ramdisk /dev/null \
        --output @(_DEPLOY_DIR)/boot.img

    cd -

    # .2 detatch the /boot and /root partitions
    # this is needed because the flasher XML expects them to be separate
    # we have /boot mount on _IMAGE_MNT_BOOT and /root mount on _IMAGE_MNT_ROOT
    # the source file from the mount is _DEPLOY_DIR/_IMAGE_NAME
    # let's dd the /boot partition to _DEPLOY_DIR/boot.img and the /root partition to _DEPLOY_DIR/root.img
    # we know from common that boot partition is
    # parted $IMAGE_PATH -s mkpart primary fat32 8 158 \
    #     set 1 lba on align-check optimal 1 \
    #     mkpart primary ext4 159 $(($MAX_IMG_SIZE - 151))
    # read the actual partition table from the image to get the correct sector offsets
    # (parted uses decimal MB and aligns to MiB boundaries, so computing offsets manually is error-prone)
    _sfdisk_out = $(sfdisk --json @(f'{_DEPLOY_DIR}/{_IMAGE_NAME}'))
    _parts = json.loads(_sfdisk_out)['partitiontable']['partitions']

    _BOOT_SKIP = _parts[0]['start']
    _BOOT_COUNT = _parts[0]['size']
    _ROOT_SKIP = _parts[1]['start']
    _ROOT_COUNT = _parts[1]['size']

    _BOOT_SIZE = _BOOT_COUNT * 512
    _ROOT_SIZE = _ROOT_COUNT * 512

    sync

    # dd the boot partition
    sudo dd \
        if=@(_DEPLOY_DIR)/@(_IMAGE_NAME) \
        of=@(_DEPLOY_DIR)/disk-sdcard.img.esp \
        bs=512 skip=@(_BOOT_SKIP) \
        count=@(_BOOT_COUNT) \
        status=none

    # dd the root partition
    sudo dd \
        if=@(_DEPLOY_DIR)/@(_IMAGE_NAME) \
        of=@(_DEPLOY_DIR)/disk-sdcard.img.root \
        bs=512 skip=@(_ROOT_SKIP) \
        count=@(_ROOT_COUNT) \
        status=none

    # .3 replace the partitions.conf.template
    with open(f"{_path}/{_MACHINE}/partitions.conf.template", 'r') as file:
        _filedata = file.read()

    with open(f"{_path}/{_MACHINE}/partitions.conf", 'w') as file:
        file.write(_filedata)

    sudo mv @(f"{_path}/{_MACHINE}")/partitions.conf \
        @(_QCOM_PTOOL_PATH)/partitions.conf

    # .3 use the qcom-ptool to create the partitions
    cd @(_QCOM_PTOOL_PATH)
    python3 gen_partition.py -i partitions.conf -o ptool-partitions.xml
    python3 ptool.py -x ptool-partitions.xml

    # .4 create the bundle for the flash
    _flash_files = [
        "gpt_backup0.bin",
        "gpt_both0.bin",
        "gpt_empty0.bin",
        "gpt_main0.bin",
        "patch0.xml",
        "rawprogram0.xml",
        "rawprogram0_BLANK_GPT.xml",
        "rawprogram0_WIPE_PARTITIONS.xml",
        "wipe_rawprogram_PHY0.xml",
        "wipe_rawprogram_PHY1.xml",
        "wipe_rawprogram_PHY2.xml",
        "wipe_rawprogram_PHY4.xml",
        "wipe_rawprogram_PHY5.xml",
        "wipe_rawprogram_PHY6.xml",
        "wipe_rawprogram_PHY7.xml",
        "zeros_1sector.bin",
        "zeros_33sectors.bin"
    ]

    sudo mkdir -p @(_DEPLOY_DIR)/flash

    for _file in _flash_files:
        sudo cp @(_QCOM_PTOOL_PATH)/@(_file) @(_DEPLOY_DIR)/flash/@(_file)

    # as we could make it easy to get only the bundle, let's also add there
    # the boot.img
    sudo cp @(_DEPLOY_DIR)/boot.img @(_DEPLOY_DIR)/flash/boot.img

else:
    Error_Out(
        f"Machine [{os.environ['MACHINE']}] is not supported",
        Error.EINVAL
    )


print("Creating qcom boot.img, OK", color=Color.WHITE, bg_color=BgColor.GREEN)
