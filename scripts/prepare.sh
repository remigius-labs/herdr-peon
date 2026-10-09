#!/bin/sh
# Step 1 of /peon: download the video, cut it into lines, write down what each says.
set -eu
[ -n "${1:-}" ] || { echo "usage: prepare.sh <youtube-url>"; exit 1; }
here=$(cd "$(dirname "$0")" && pwd)
clips="${XDG_DATA_HOME:-$HOME/.local/share}/herdr-peon/clips"
rm -rf "$clips"
sh "$here/get-clips.sh" "$1" "$clips"
sh "$here/transcribe.sh" "$clips"
echo
echo "Done. Back to Claude: say 'sort them'."
