#!/bin/sh

touchpad='ELAN06FA:00 04F3:327E Touchpad'

if ! xinput list --name-only | grep -Fxq "$touchpad"; then
    exit 0
fi

xinput set-prop "$touchpad" 'libinput Tapping Enabled' 1 2>/dev/null || true
xinput set-prop "$touchpad" 'libinput Tapping Drag Enabled' 1 2>/dev/null || true
xinput set-prop "$touchpad" 'libinput Natural Scrolling Enabled' 1 2>/dev/null || true
xinput set-prop "$touchpad" 'libinput Accel Speed' 0.5 2>/dev/null || true
xinput set-prop "$touchpad" 'libinput Click Method Enabled' 0 1 2>/dev/null || true
