#!/bin/bash

set -e

echo "Installing target aktualizr..."

cd $BUILD_ROOT/aktualizr-torizon
cd build/

# INSTALL!
sudo -k \
    make install

sudo -k \
    ldconfig
