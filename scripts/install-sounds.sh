#!/bin/sh
# Copy sorted clips into Herdr and point Herdr's done/request sounds at shuffled symlinks. Safe to re-run.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
clips="${1:-${XDG_DATA_HOME:-$HOME/.local/share}/herdr-peon/clips}"
snd="$HOME/.config/herdr/sounds"
cfg="$HOME/.config/herdr/config.toml"
shuffle="$here/shuffle.sh"

# clips/{ack,request,done,annoyed}/: first prompt of a session, agent needs you, agent finished, kept aside
# Optional sort from /peon: ack=01,02 request=03:what-you-want,04 done=07 annoyed=14.
# A clip is filed under the name after the colon, else under a name from its transcript.
if [ $# -gt 0 ] && [ "${1#*=}" != "$1" ]; then
  clips="${XDG_DATA_HOME:-$HOME/.local/share}/herdr-peon/clips"
  for arg in "$@"; do
    pool=${arg%%=*}
    case $pool in ack|request|done|annoyed) ;; *) echo "unknown bucket: $pool"; exit 1 ;; esac
    mkdir -p "$clips/$pool"
    for item in $(echo "${arg#*=}" | tr ',' ' '); do
      n=${item%%:*}
      [ -f "$clips/$n.mp3" ] || { echo "no clip $n.mp3"; exit 1; }
      if [ "$item" != "$n" ]; then name=${item#*:}
      else name=$(awk -F'\t' -v f="$n.mp3" '$1 == f { print $3 }' "$clips/transcript.tsv"); fi
      name=$(printf '%s' "$name" | tr 'A-Z' 'a-z' | tr -cs 'a-z0-9' '-' | sed 's/^-*//; s/-*$//')
      dest="$clips/$pool/${name:-$n}.mp3"
      [ -e "$dest" ] && dest="$clips/$pool/${name:-$n}-$n.mp3"
      mv "$clips/$n.mp3" "$dest"
    done
  done
fi
ls "$clips/request"/*.mp3 >/dev/null 2>&1 || { echo "no clips in $clips/request, sort the clips first"; exit 1; }
# A new unit replaces the old one; the old clips move to previous/ so a swap can be undone.
rm -rf "$snd/previous"
for pool in ack request done annoyed; do
  [ -d "$snd/$pool" ] && mkdir -p "$snd/previous" && mv "$snd/$pool" "$snd/previous/$pool"
done
for pool in ack request done annoyed; do
  ls "$clips/$pool"/*.mp3 >/dev/null 2>&1 || continue
  mkdir -p "$snd/$pool"
  cp "$clips/$pool"/*.mp3 "$snd/$pool/"
  echo "$pool clips: $(ls "$snd/$pool" | wc -l)"
done
"$shuffle"

touch "$cfg"
cp "$cfg" "$cfg.bak-peon"
python3 - "$cfg" "$snd" <<'PY'
import re, sys
p, snd = sys.argv[1:]
text = open(p).read()
block = f'[ui.sound]\nenabled = true\npath = "{snd}/request.mp3"\ndone_path = "{snd}/done.mp3"\nrequest_path = "{snd}/request.mp3"\n'
if re.search(r"^\[ui\.sound\]\n", text, re.M):
    text = re.sub(r"^\[ui\.sound\]\n(?:(?!\[)[^\n]*\n?)*", block + "\n", text, count=1, flags=re.M)
    print("herdr config: [ui.sound] updated")
else:
    text = text.rstrip("\n") + "\n\n" + block
    print("herdr config: [ui.sound] added")
open(p, "w").write(text)
PY

# Shuffle for every agent Herdr runs, not only Claude: a user timer picks new lines every minute.
data="${XDG_DATA_HOME:-$HOME/.local/share}/herdr-peon"
units="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
mkdir -p "$data" "$units"
cp "$shuffle" "$data/shuffle.sh"
printf '[Unit]\nDescription=herdr-peon: shuffle voice lines\n\n[Service]\nType=oneshot\nExecStart=/bin/sh %s/shuffle.sh\n' "$data" > "$units/herdr-peon-shuffle.service"
printf '[Unit]\nDescription=herdr-peon: shuffle voice lines every minute\n\n[Timer]\nOnBootSec=1min\nOnUnitActiveSec=1min\n\n[Install]\nWantedBy=timers.target\n' > "$units/herdr-peon-shuffle.timer"
systemctl --user daemon-reload && systemctl --user enable --now herdr-peon-shuffle.timer >/dev/null && echo "shuffle timer: on"

herdr server reload-config >/dev/null && echo "herdr: config reloaded"
