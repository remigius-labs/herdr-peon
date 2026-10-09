#!/bin/sh
# Play a random ack clip on the first prompt of a new agent session, like a fresh unit's first order.
# Reads the Claude Code hook JSON on stdin for the session id.
seen="${XDG_STATE_HOME:-$HOME/.local/state}/herdr-peon/seen"
mkdir -p "$seen"
id=$(sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)
[ -n "$id" ] || exit 0
[ -e "$seen/$id" ] && exit 0
touch "$seen/$id"
find "$seen" -type f -mtime +7 -delete 2>/dev/null
pick=$(ls "$HOME/.config/herdr/sounds/ack"/*.mp3 2>/dev/null | shuf -n1)
[ -n "$pick" ] && setsid -f pw-play "$pick" </dev/null >/dev/null 2>&1
exit 0
