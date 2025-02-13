#!/usr/bin/python3

import os
import json
import subprocess

# gaia need to previously set architecture and machine
ARCH = os.environ.get("ARCH")
MACHINE = os.environ.get("MACHINE")
BUILD_PATH = os.environ.get("BUILD_PATH")

# read the meta data
meta = json.loads(os.environ.get("META"))

if not os.path.exists(f"{BUILD_PATH}/tmp/{MACHINE}/EasySplash"):
    # clone
    print(f"cloning {meta['source']} ...")
    subprocess.run(
        f"git clone {meta['source']} {BUILD_PATH}/tmp/{MACHINE}/EasySplash",
        shell=True,
        check=True,
        executable="/bin/bash",
        env=os.environ
    )
else:
    # reset all
    print(f"resetting {meta['name']} ...")
    subprocess.run(
        f"git -C {BUILD_PATH}/tmp/{MACHINE}/EasySplash reset --hard",
        shell=True,
        check=True,
        executable="/bin/bash",
        env=os.environ
    )

    # fetch
    print(f"fetching {meta['name']} ...")
    subprocess.run(
        f"git -C {BUILD_PATH}/tmp/{MACHINE}/EasySplash fetch",
        shell=True,
        check=True,
        executable="/bin/bash",
        env=os.environ
    )

# set the working directory
os.chdir(f"{BUILD_PATH}/tmp/{MACHINE}/EasySplash")

# checkout
print(f"checkout {meta['ref'][ARCH]} ...")
subprocess.run(
    f"git checkout {meta['ref'][ARCH]}",
    shell=True,
    check=True,
    executable="/bin/bash",
    env=os.environ
)

print(f"{meta['name']} cloned to {BUILD_PATH}/tmp/{MACHINE}/EasySplash")
