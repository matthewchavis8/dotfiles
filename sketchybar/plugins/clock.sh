#!/bin/sh

sketchybar --set "$NAME" label="$(TZ=America/Chicago date '+%I:%M:%S %p %Y-%m-%d')"
