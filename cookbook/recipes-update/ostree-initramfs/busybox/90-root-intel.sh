#!/bin/busybox sh

get_parent_block_dev() {
    _dev_base=$(basename "$1")
    _sys_block_path=$(readlink -f "/sys/class/block/$_dev_base")

    # If this is already a whole-disk node, parent == device name.
    _parent_base=$(basename "$(dirname "$_sys_block_path")")
    if [ "$_parent_base" = "$_dev_base" ]; then
        echo "$_dev_base"
    else
        echo "$_parent_base"
    fi
}

is_on_removable_disk() {
    _parent_disk=$(get_parent_block_dev "$1")
    _removable_file="/sys/block/$_parent_disk/removable"

    [ -r "$_removable_file" ] && [ "$(cat "$_removable_file")" = "1" ]
}

find_label_candidates() {
    _label="$1"

    get_ext_label() {
        _node="$1"
        _ext_magic=$(dd if="$_node" bs=1 skip=1080 count=2 2>/dev/null | od -An -tx1 | tr -d ' \n')
        [ "$_ext_magic" = "53ef" ] || return 1

        dd if="$_node" bs=1 skip=1144 count=16 2>/dev/null | tr -d '\000'
    }

    get_fat_label() {
        _node="$1"

        _fat32_sig=$(dd if="$_node" bs=1 skip=82 count=8 2>/dev/null)
        if [ "$_fat32_sig" = "FAT32   " ]; then
            dd if="$_node" bs=1 skip=71 count=11 2>/dev/null
            return 0
        fi

        _fat16_sig=$(dd if="$_node" bs=1 skip=54 count=8 2>/dev/null)
        if [ "$_fat16_sig" = "FAT16   " ] || [ "$_fat16_sig" = "FAT12   " ]; then
            dd if="$_node" bs=1 skip=43 count=11 2>/dev/null
            return 0
        fi

        return 1
    }

    trim_label() {
        echo "$1" | sed 's/[[:space:]]*$//'
    }

    _target_label=$(trim_label "$_label")
    _target_label_upper=$(echo "$_target_label" | tr '[:lower:]' '[:upper:]')

    for _sys_dev in /sys/class/block/*; do
        [ -e "$_sys_dev/partition" ] || continue

        _node="/dev/$(basename "$_sys_dev")"
        [ -b "$_node" ] || continue

        _node_label=$(get_ext_label "$_node")
        if [ -n "$_node_label" ]; then
            _node_label=$(trim_label "$_node_label")
            [ "$_node_label" = "$_target_label" ] && echo "$_node"
            continue
        fi

        _node_label=$(get_fat_label "$_node")
        if [ -n "$_node_label" ]; then
            _node_label=$(trim_label "$_node_label")
            _node_label_upper=$(echo "$_node_label" | tr '[:lower:]' '[:upper:]')
            [ "$_node_label_upper" = "$_target_label_upper" ] && echo "$_node"
        fi
    done
}

if [ "${root#LABEL:}" != "$root" ]; then
    _label="${root#*:}"
    echo "[initramfs] searching for root partition with label $_label"

    # Wait for the device to be available
    timeout=30 # Timeout in seconds
    interval=1 # Interval between checks in seconds
    elapsed=0

    # if we have the kernel arg zeus_install=1
    # propably we need some additional time to have the target disk available
    if [ "$zeus_install" = "1" ]; then
        sleep 10
    fi

    while [ -z "$_dev" ]; do
        sleep $interval

        # Collect every device that matches the requested label.
        # The function uses the best available method in this initramfs.
        _candidates=$(find_label_candidates "$_label")

        if [ -n "$_candidates" ]; then
            set -- $_candidates

            if [ $# -eq 1 ]; then
                _dev="$1"
            else
                echo "[initramfs] found multiple root candidates: $_candidates"

                # Prefer a root candidate on the same disk that holds BOOT-INTEL.
                # If no match is found, pick the first candidate deterministically.
                _dev=""
                _boot_candidates=$(find_label_candidates "BOOT-INTEL")
                if [ -n "$_boot_candidates" ]; then
                    echo "[initramfs] BOOT-INTEL found at: $_boot_candidates"

                    for _candidate in "$@"; do
                        _candidate_disk=$(get_parent_block_dev "$_candidate")

                        for _boot_candidate in $_boot_candidates; do
                            _boot_disk=$(get_parent_block_dev "$_boot_candidate")
                            if [ "$_candidate_disk" = "$_boot_disk" ]; then
                                _dev="$_candidate"
                                echo "[initramfs] selected candidate on BOOT-INTEL disk: $_dev"
                                break
                            fi
                        done

                        [ -n "$_dev" ] && break
                    done
                fi

                [ -z "$_dev" ] && _dev="$1"
            fi
        fi

        elapsed=$((elapsed + interval))

        if [ $elapsed -ge $timeout ]; then
            echo "[initramfs] root device find timeout"
            exit 69
        fi
    done

    echo "[initramfs] root partition label $_label found at $_dev"

    # clean the symlink for the mplayer
    rm -rf /sysroot
    mkdir -p /sysroot
    mount -t ext4 $_dev /sysroot

    echo "[initramfs] root partition $root mounted"

else
    echo "[initramfs] root partition argument not found"
    exit 69
fi
