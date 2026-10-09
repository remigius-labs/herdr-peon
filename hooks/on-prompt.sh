#!/bin/sh
# First prompt of a Claude session: play an order line.
root="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
sh "$root/scripts/ack.sh"
exit 0
