#!/usr/bin/env bash

WALL_DIR="$HOME/Pictures/bgImages"

# Pick an image via rofi
chosen="$(find "$WALL_DIR" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
  | sort \
  | rofi -dmenu -i -p "Wallpaper")"

[ -z "$chosen" ] && exit 0

# Apply + save to feh config without aggressive upscale/crop.
feh --bg-max "$chosen"
