#!/bin/bash
# Get the device ID of the TouchPad
TOUCHPAD_ID=$(xinput list | grep -i "TouchPad" | grep -o 'id=[0-9]*' | cut -d= -f2)
# Set the property to enable tapping
xinput set-prop $TOUCHPAD_ID "libinput Tapping Enabled" 1
