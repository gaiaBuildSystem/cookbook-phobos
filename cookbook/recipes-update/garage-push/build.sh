#!/bin/bash

set -e

echo "Building aktualizr..."

cd $BUILD_ROOT/aktualizr

mkdir -p build
cd build/

cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_DEB=ON \
    -DBUILD_SOTA_TOOLS=ON \
    -DGARAGE_SIGN_ARCHIVE=$BUILD_ROOT/uptane-sign/cli-$UPTANE_SIGN_VER.tgz \
    -DGARAGE_SIGN_TOOL="uptane-sign" \
    -DSOTA_DEBIAN_PACKAGE_DEPENDS=openjdk-17-jre-headless \
    -DBUILD_OSTREE=ON \
    -DWARNING_AS_ERROR=OFF \
    ..

mkdir -p $BUILD_ROOT/aktualizr/install-dir

# WARN: THIS IS NOT MEANING TO BE RUN IN YOUR LOCAL MACHINE
# This should run in the dev container only
echo $USER_PASSWD | sudo -k -S \
    make -j"$(nproc)"

echo $USER_PASSWD | sudo -k -S \
    make install

echo $USER_PASSWD | sudo -k -S \
    ldconfig
