#!/bin/sh
# Re-point Herdr's sound at a random clip. Runs on every prompt, so the next ping is a new line.
dir="$HOME/.config/herdr/sounds"
pick=$(ls "$dir"/peon/*.mp3 2>/dev/null | shuf -n1)
[ -n "$pick" ] && ln -sfn "$pick" "$dir/peon.mp3"
exit 0
