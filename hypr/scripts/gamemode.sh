#!/bin/bash
if [ -f /tmp/gamemode_on ]; then
    rm /tmp/gamemode_on
    notify-send -u low -t 2000 '󰊗 Game Mode' 'Disabled'
else
    touch /tmp/gamemode_on
    notify-send -u low -t 2000 '󰊗 Game Mode' 'Enabled'
fi
hyprctl reload
