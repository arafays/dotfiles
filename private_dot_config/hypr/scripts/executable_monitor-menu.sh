#!/bin/bash

monitor="HDMI-A-1"

choice=$(echo -e "Toggle Secondary Monitor\nTurn Off Secondary Monitor\nTurn On Secondary Monitor" | wofi --dmenu --prompt "Monitor Control")

case $choice in
"Toggle Secondary Monitor")
    if hyprctl monitors | grep -q "$monitor"; then
        hyprctl dispatch dpms off "$monitor"
    else
        hyprctl dispatch dpms on "$monitor"
    fi
    ;;
"Turn Off Secondary Monitor")
    hyprctl dispatch dpms off "$monitor"
    ;;
"Turn On Secondary Monitor")
    hyprctl dispatch dpms on "$monitor"
    ;;
esac