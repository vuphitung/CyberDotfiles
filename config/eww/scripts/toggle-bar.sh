#!/bin/bash
# NC2077 — Toggle bar, không kill daemon
CFG="$HOME/CyberDotfiles/config/eww"

if eww --config "$CFG" active-windows 2>/dev/null | grep -q "^bar$"; then
  eww --config "$CFG" close bar
else
  eww --config "$CFG" open bar
fi
