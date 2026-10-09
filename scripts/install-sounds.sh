#!/bin/sh
# Copy sorted clips into Herdr and point Herdr's done/request sounds at shuffled symlinks. Safe to re-run.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
clips="${1:-${XDG_DATA_HOME:-$HOME/.local/share}/herdr-peon/clips}"
snd="$HOME/.config/herdr/sounds"
cfg="$HOME/.config/herdr/config.toml"
shuffle="$here/shuffle.sh"

# clips/{ack,request,done,annoyed}/: first prompt of a session, agent needs you, agent finished, kept aside
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
