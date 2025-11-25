#!/bin/bash

monitor="HDMI-A-1"

if hyprctl monitors | grep -q "$monitor"; then
    hyprctl dispatch dpms off "$monitor"
else
    hyprctl dispatch dpms on "$monitor"
fi