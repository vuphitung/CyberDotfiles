#!/bin/bash
SOCK="${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"

_cleanup() { kill 0 2>/dev/null; exit 0; }
trap _cleanup EXIT INT TERM HUP

hyprctl activeworkspace -j 2>/dev/null | jq -r '.id // 1'

while IFS= read -r line; do
  case "$line" in
    "workspace>>"*)   echo "${line#*>>}" ;;
    "focusedmon>>"*)  hyprctl activeworkspace -j 2>/dev/null | jq -r '.id // 1' ;;
  esac
done < <(socat -u UNIX-CONNECT:"$SOCK" - 2>/dev/null)
