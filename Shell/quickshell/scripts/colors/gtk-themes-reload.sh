#!/usr/bin/env bash

current=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || echo "'prefer-dark'")
current_theme=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null || echo "'adw-gtk3-dark'")

gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita' 2>/dev/null || true

if [[ "$current" == "'prefer-dark'" ]]; then
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-light' 2>/dev/null || true
    sleep 0.5
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
else
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
    sleep 0.5
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-light' 2>/dev/null || true
fi

gsettings set org.gnome.desktop.interface gtk-theme "$current_theme" 2>/dev/null || true
