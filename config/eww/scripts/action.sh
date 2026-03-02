#!/bin/bash

case $1 in
  # ─── WIFI ──────────────────────────────────────────────
  toggle-wifi)
    nmcli radio wifi | grep -q "enabled" \
      && nmcli radio wifi off \
      || nmcli radio wifi on ;;
  open-wifi)
    kitty --class floating_term -e nmtui & ;;

  # ─── BLUETOOTH ─────────────────────────────────────────
  toggle-bt)
    bluetoothctl show | grep -q "Powered: yes" \
      && bluetoothctl power off \
      || bluetoothctl power on ;;
  open-bt)
    blueman-manager &>/dev/null \
      || kitty --class floating_term -e bluetoothctl & ;;

  # ─── DND ───────────────────────────────────────────────
  toggle-dnd)
    swaync-client -d -sw ;;

  # ─── NIGHT MODE ────────────────────────────────────────
  toggle-night)
    pgrep -x "gammastep" >/dev/null \
      && pkill gammastep \
      || gammastep -O 3500 -b 0.9 & ;;

  # ─── VOLUME ────────────────────────────────────────────
  set-vol)
    val=$(echo "$2" | awk '{printf "%d", $1}')
    [ "$val" -gt 100 ] && val=100
    [ "$val" -lt 0 ]   && val=0
    pamixer --set-volume "$val" ;;
  toggle-mute)
    pamixer --toggle-mute ;;

  # ─── MIC ───────────────────────────────────────────────
  set-mic)
    val=$(echo "$2" | awk '{printf "%d", $1}')
    [ "$val" -gt 100 ] && val=100
    [ "$val" -lt 0 ]   && val=0
    pamixer --default-source --set-volume "$val" ;;
  toggle-mic-mute)
    pamixer --default-source --toggle-mute ;;

  # ─── BRIGHTNESS ────────────────────────────────────────
  set-bright)
    val=$(echo "$2" | awk '{printf "%d", $1}')
    [ "$val" -gt 100 ] && val=100
    [ "$val" -lt 1 ]   && val=1
    brightnessctl s "${val}%" ;;

  # ─── MEDIA ─────────────────────────────────────────────
  play-pause) playerctl play-pause ;;
  next)       playerctl next ;;
  prev)       playerctl previous ;;

  # ─── APPS ──────────────────────────────────────────────
  app-browser)  thorium-browser --enable-features=UseOzonePlatform --ozone-platform=wayland & ;;
  app-spotify)  spotify & ;;
  app-term)     kitty & ;;
  app-code)     code & ;;
  app-files)    nautilus & ;;
esac
