#!/bin/sh
# Point Herdr's done and request sounds at a random clip from each pool. Runs on every prompt.
snd="$HOME/.config/herdr/sounds"
for pool in done request; do
  pick=$(ls "$snd/$pool"/*.mp3 2>/dev/null | shuf -n1)
  [ -n "$pick" ] && ln -sfn "$pick" "$snd/$pool.mp3"
done
exit 0
