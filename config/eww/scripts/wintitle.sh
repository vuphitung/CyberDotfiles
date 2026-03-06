#!/bin/bash
SOCK="${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"

_cleanup() { kill 0 2>/dev/null; exit 0; }
trap _cleanup EXIT INT TERM HUP

_clean() {
  printf '%s' "$1" | iconv -f utf-8 -t utf-8 -c 2>/dev/null | head -1 | cut -c1-38
}
_get_active() {
  local t; t=$(hyprctl activewindow -j 2>/dev/null | jq -r '.title // ""')
  [[ -n "$t" && "$t" != "null" ]] && _clean "$t" || echo "HYPR//READY"
}

_get_active

while IFS= read -r line; do
  case "$line" in
    "activewindow>>"*)
      title="${line#*,}"
      [[ -n "$title" ]] && _clean "$title" || _get_active ;;
    "closewindow>>"*|"workspace>>"*|"focusedmon>>"*)
      _get_active ;;
  esac
done < <(socat -u UNIX-CONNECT:"$SOCK" - 2>/dev/null)
