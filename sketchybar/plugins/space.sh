#!/bin/sh

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

resolve_workspace() {
  raw="$1"

  if [ -n "$raw" ] && [ "${raw#\$}" = "$raw" ]; then
    parsed="$(printf '%s\n' "$raw" | sed -E 's/.*AEROSPACE_FOCUSED_WORKSPACE=//; s/.*workspace[[:space:]]+//; s/[^[:alnum:]]//g')"
    if [ -n "$parsed" ]; then
      printf '%s\n' "$parsed"
      return
    fi
  fi

  aerospace list-workspaces --focused 2>/dev/null
}

FOCUSED="$(resolve_workspace "${AEROSPACE_FOCUSED_WORKSPACE:-$INFO}")"

if [ -z "$FOCUSED" ]; then
  exit 0
fi

sketchybar --set "$NAME" label="$FOCUSED" label.color=0xffffffff
