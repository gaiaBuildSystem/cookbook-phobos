#!/bin/bash

set -e

echo "Building mplayer-splash..."
cd $BUILD_PATH/tmp/$MACHINE/mplayer

chmod +x phobos-build.sh
./phobos-build.sh
