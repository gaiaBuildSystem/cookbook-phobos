#!/bin/bash

set -e

echo "Installing target aktualizr..."

cd $BUILD_ROOT/aktualizr-torizon
cd build/

# INSTALL!
echo $USER_PASSWD | sudo -k -S \
    make install

echo $USER_PASSWD | sudo -k -S \
    ldconfig
