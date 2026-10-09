#!/bin/sh
# Every prompt: keep a stable path to the plugin for the commands /peon hands to the user.
# First prompt of a Claude session: play an order line.
root="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
data="${XDG_DATA_HOME:-$HOME/.local/share}/herdr-peon"
mkdir -p "$data" && ln -sfn "$root" "$data/plugin"
sh "$root/scripts/ack.sh"
exit 0
