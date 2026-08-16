#!/usr/bin/env bash

_ACTUAL="/usr/share/sota"
_NEXT_OSTREE_HASH=$(mars deploy-next)
_NEXT="/sysroot/ostree/deploy/phobos/deploy/${_NEXT_OSTREE_HASH}/usr/share/sota"

function need_update_device_tree() {
    # compare the versions from the actual and next directories
    _ACTUAL_VERSION=$(jq -r '.update_version' ${_ACTUAL}/device-tree.json)
    _NEXT_VERSION=$(jq -r '.update_version' ${_NEXT}/device-tree.json)

    echo "actual=${_ACTUAL_VERSION} :: next=${_NEXT_VERSION}"

    # return 0 if update is needed, 1 otherwise
    if [ "$_ACTUAL_VERSION" != "$_NEXT_VERSION" ]; then
        return 0
    else
        return 1
    fi
}

function update_device_tree() {
    # if there is .bak files remove it
    find /var/rootdirs/media/u-boot/ -name "*.dtb.bak" -type f -delete

    # create the backup of the current .dtb files
    for dtb in /var/rootdirs/media/u-boot/*.dtb; do
        cp -f ${dtb} ${dtb}.bak
    done

    # on raspberry pi we need to also check the config.txt file
    # if we had a rollback situation, we need to backup the config.txt
    if [ -f /var/rootdirs/media/u-boot/config.txt.bak.1 ]; then
        mv -f /var/rootdirs/media/u-boot/config.txt /var/rootdirs/media/u-boot/config.txt.bak
        mv -f /var/rootdirs/media/u-boot/config.txt.bak.1 /var/rootdirs/media/u-boot/config.txt
    fi

    # copy all the .dtb files from NEXT to /boot
    cp -f ${_NEXT}/*.dtb /var/rootdirs/media/u-boot/
}

# check if the /usr/share/sota/device-tree.json file exists
if [ ! -f /usr/share/sota/device-tree.json ]; then
    # if it does not exists always update the device tree
    echo "device-tree.json does not exist, forcing device tree update"
    update_device_tree

else
    echo "device-tree.json exists, checking if update is needed"
    if need_update_device_tree; then
        echo "device tree update needed, updating ..."
        update_device_tree
    fi
fi

# force the new deploy after aktualizr completes
/sbin/reboot
