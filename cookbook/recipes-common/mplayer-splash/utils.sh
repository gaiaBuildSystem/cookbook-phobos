#!/bin/bash

set -e

_path=$(dirname "$0")


cd /
staticx /usr/bin/fbset fbset


# copy the static binaries to the initramfs folder
mv /fbset $INITRAMFS_PATH/bin/fbset
