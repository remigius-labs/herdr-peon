#!/bin/sh
# Copy clips into Herdr, point Herdr's sound at a shuffled symlink, add the Claude Code hook. Safe to re-run.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
clips="${1:-$here/clips}"
snd="$HOME/.config/herdr/sounds"
cfg="$HOME/.config/herdr/config.toml"
set_json="$HOME/.claude/settings.json"
shuffle="$here/shuffle.sh"

ls "$clips"/*.mp3 >/dev/null 2>&1 || { echo "no mp3s in $clips, run ./get-clips.sh first"; exit 1; }
mkdir -p "$snd/peon"
cp "$clips"/*.mp3 "$snd/peon/"
"$shuffle"
echo "clips: $(ls "$snd/peon" | wc -l)"

touch "$cfg"
if ! grep -q '^\[ui.sound\]' "$cfg"; then
  printf '\n[ui.sound]\nenabled = true\npath = "%s/peon.mp3"\n' "$snd" >> "$cfg"
  echo "herdr config: [ui.sound] added"
else
  echo "herdr config: [ui.sound] already there, set path = \"$snd/peon.mp3\" by hand"
fi

[ -f "$set_json" ] || echo '{}' > "$set_json"
if ! grep -q 'herdr-peon\|peon-shuffle\|shuffle.sh' "$set_json"; then
  cp "$set_json" "$set_json.bak-peon"
  python3 - "$set_json" "$shuffle" <<'PY'
import json, sys
p, cmd = sys.argv[1], sys.argv[2]
d = json.load(open(p))
d.setdefault("hooks", {}).setdefault("UserPromptSubmit", []).append(
    {"hooks": [{"type": "command", "command": cmd, "timeout": 5}]})
json.dump(d, open(p, "w"), indent=2)
PY
  echo "claude hook: added (backup at settings.json.bak-peon)"
else
  echo "claude hook: already there"
fi

herdr server reload-config && echo "herdr: config reloaded"
