#!/bin/bash

set -e

echo "Building easy-splash..."

# instal the cargo toolchain
curl https://sh.rustup.rs -sSf | sh -s -- -y
source $HOME/.cargo/env

cd $BUILD_PATH/tmp/$MACHINE/EasySplash
cargo build
