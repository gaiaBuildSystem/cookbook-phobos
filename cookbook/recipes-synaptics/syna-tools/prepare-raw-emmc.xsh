#!/usr/bin/env xonsh

# Copyright (c) 2025 MicroHobby
# SPDX-License-Identifier: MIT

# use the xonsh environment to update the OS environment
$UPDATE_OS_ENVIRON = True
# always return if a cmd fails
$XONSH_SUBPROC_CMD_RAISE_ERROR = True


import os
import json
import os.path
from torizon_templates_utils.colors import print,BgColor,Color
from torizon_templates_utils.errors import Error_Out,Error


print("syna-tools preparing raw emmc image ...", color=Color.WHITE, bg_color=BgColor.GREEN)

print(
    "THIS ONLY OVERWRITES THE ORIGINAL COOKBOOK-SYNAPTICS RECIPE!\n" +
    "FOR OTA WE USE THE prepare-ota-emmc.xsh RECIPE INSTEAD THAT GOES AFTER BUNDLE",
    color=Color.BLACK,
    bg_color=BgColor.WHITE
)

print("syna-tools preparing raw emmc image, OK", color=Color.WHITE, bg_color=BgColor.GREEN)
