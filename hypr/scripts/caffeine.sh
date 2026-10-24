#!/bin/bash
if pidof hypridle > /dev/null; then
    pkill hypridle
    notify-send -u low -t 2000 ' Caffeine Mode' 'Enabled'
else
    hypridle > /dev/null 2>&1 & disown
    notify-send -u low -t 2000 ' Caffeine Mode' 'Disabled'
fi
