#!/bin/bash

choice=$(echo -e "lock\nlogout\nsleep\nshutdown\nreboot" | wofi --dmenu --prompt "Power Menu")

case $choice in
lock)
  hyprlock
  ;;
logout)
  uwsm stop
  ;;
sleep)
  systemctl suspend
  ;;
shutdown)
  systemctl poweroff
  ;;
reboot)
  systemctl reboot
  ;;
esac
