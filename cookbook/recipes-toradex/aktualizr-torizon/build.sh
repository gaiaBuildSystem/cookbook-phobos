#!/bin/bash

set -e

echo "Building aktualizr..."

cd $BUILD_ROOT/aktualizr-torizon

mkdir -p build
cd build/

cmake \
    -DAKTUALIZR_VERSION=$DEB_VERSION_UPSTREAM \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_DEB=ON \
    -DBUILD_SOTA_TOOLS=ON \
    -DGARAGE_SIGN_ARCHIVE=$BUILD_ROOT/uptane-sign/cli-$UPTANE_SIGN_VER.tgz \
    -DGARAGE_SIGN_TOOL="uptane-sign" \
    -DSOTA_DEBIAN_PACKAGE_DEPENDS=openjdk-17-jre-headless \
    -DBUILD_OSTREE=ON \
    -DBUILD_TESTING=OFF \
    -DCMAKE_LIBRARY_PATH=$DEB_HOST_MULTIARCH \
    -DWARNING_AS_ERROR=OFF \
    ..

# WARN: THIS IS NOT MEANING TO BE RUN IN YOUR LOCAL MACHINE
# This should run in the dev container only
sudo -k \
    make -j"$(nproc)"

sudo -k \
    make package
