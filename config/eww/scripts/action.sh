#!/bin/bash
# CYBER//ACTION — Instant Feedback + Anti-Freeze Edition
# Fixes: & trong yuck, lock expire, optimistic update, verify async 2s

EWW_CFG="$HOME/CyberDotfiles/config/eww"
LOCK_DIR="/tmp/eww_action_locks"
mkdir -p "$LOCK_DIR"

# Lock với auto-expire 10s — tránh kẹt khi spam
_lock() {
  local f="$LOCK_DIR/$1.lock"
  if [[ -f "$f" ]]; then
    local age=$(( $(date +%s) - $(stat -c %Y "$f" 2>/dev/null || echo 0) ))
    [[ $age -lt 10 ]] && return 1   # còn trong 10s → bỏ qua
    rm -f "$f"                       # quá 10s → reset
  fi
  touch "$f"
  trap "rm -f '$f'" EXIT
  return 0
}

# Optimistic update — đổi 1 field trong hub_slow NGAY LẬP TỨC
_set_slow() {
  local field="$1" val="$2"
  local cur updated
  cur=$(eww get hub_slow 2>/dev/null || echo "{}")
  updated=$(echo "$cur" | jq -c --arg v "$val" ".${field}=\$v")
  eww update hub_slow="$updated" 2>/dev/null
}

# Verify từ hardware sau 2s — chạy ngầm hoàn toàn, không block
_verify_slow() {
  (
    sleep 2
    eww update hub_slow="$("$EWW_CFG/scripts/hub.sh" slow)" 2>/dev/null
  ) &
}

_refresh_fast() {
  (
    sleep 0.15
    eww update hub_fast="$("$EWW_CFG/scripts/hub.sh" fast)" 2>/dev/null
  ) &
}

case $1 in

  # ─── WIFI ──────────────────────────────────────────────
  toggle-wifi)
    _lock "wifi" || exit 0
    cur=$(eww get hub_slow 2>/dev/null | jq -r '.wifi // "OFF"')
    if [[ "$cur" == "ON" ]]; then
      _set_slow wifi "OFF"
      timeout 5s nmcli radio wifi off &>/dev/null
    else
      _set_slow wifi "ON"
      timeout 5s nmcli radio wifi on &>/dev/null
    fi
    _verify_slow
    ;;
  open-wifi)
    kitty --class floating_term -e nmtui &
    ;;

  # ─── BLUETOOTH ─────────────────────────────────────────
  toggle-bt)
    _lock "bt" || exit 0
    cur=$(eww get hub_slow 2>/dev/null | jq -r '.bt // "OFF"')
    if [[ "$cur" == "ON" ]]; then
      _set_slow bt "OFF"
      timeout 5s bluetoothctl power off &>/dev/null
    else
      _set_slow bt "ON"
      timeout 5s bluetoothctl power on &>/dev/null
    fi
    _verify_slow
    ;;
  open-bt)
    blueman-manager &>/dev/null \
      || kitty --class floating_term -e bluetoothctl &
    ;;

  # ─── DND ───────────────────────────────────────────────
  toggle-dnd)
    _lock "dnd" || exit 0
    cur=$(eww get hub_slow 2>/dev/null | jq -r '.dnd // "OFF"')
    if [[ "$cur" == "ON" ]]; then
      _set_slow dnd "OFF"
    else
      _set_slow dnd "ON"
    fi
    swaync-client -d -sw &>/dev/null
    _verify_slow
    ;;

  # ─── NIGHT MODE ────────────────────────────────────────
  toggle-night)
    _lock "night" || exit 0
    if pgrep -x "gammastep" >/dev/null; then
      _set_slow night "OFF"
      pkill gammastep
    else
      _set_slow night "ON"
      gammastep -O 3500 -b 0.88 &
      disown
    fi
    ;;

  # ─── VOLUME ────────────────────────────────────────────
  set-vol)
    val=$(printf "%d" "${2%.*}" 2>/dev/null || echo 0)
    [ "$val" -gt 100 ] && val=100
    [ "$val" -lt 0   ] && val=0
    pamixer --set-volume "$val"
    ;;
  toggle-mute)
    pamixer --toggle-mute
    _refresh_fast
    ;;

  # ─── MIC ───────────────────────────────────────────────
  set-mic)
    val=$(printf "%d" "${2%.*}" 2>/dev/null || echo 0)
    [ "$val" -gt 100 ] && val=100
    [ "$val" -lt 0   ] && val=0
    pamixer --default-source --set-volume "$val"
    ;;
  toggle-mic-mute)
    pamixer --default-source --toggle-mute
    _refresh_fast
    ;;

  # ─── BRIGHTNESS ────────────────────────────────────────
  set-bright)
    val=$(printf "%d" "${2%.*}" 2>/dev/null || echo 50)
    [ "$val" -gt 100 ] && val=100
    [ "$val" -lt 1   ] && val=1
    brightnessctl s "${val}%"
    ;;

  # ─── MEDIA ─────────────────────────────────────────────
  play-pause) playerctl play-pause ;;
  next)       playerctl next       ;;
  prev)       playerctl previous   ;;

  # ─── APPS ──────────────────────────────────────────────
  app-browser) thorium-browser --enable-features=UseOzonePlatform --ozone-platform=wayland & ;;
  app-spotify) spotify  & ;;
  app-term)    kitty    & ;;
  app-code)    code     & ;;
  app-files)   nautilus & ;;

esac
