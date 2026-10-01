#!/bin/sh
# Download a voice-line compilation and cut it into one mp3 per line, split on silence.
# Usage: ./get-clips.sh <youtube-url> [out-dir]
set -eu
url="${1:?usage: get-clips.sh <youtube-url> [out-dir]}"
out="${2:-clips}"
mkdir -p "$out"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

yt-dlp -q -x --audio-format mp3 -o "$tmp/full.%(ext)s" "$url"
ffmpeg -hide_banner -i "$tmp/full.mp3" -af silencedetect=noise=-35dB:d=0.25 -f null - 2>"$tmp/sil.txt" || true

python3 - "$tmp/full.mp3" "$tmp/sil.txt" "$out" <<'PY'
import re, subprocess, sys
src, log, out = sys.argv[1:]
text = open(log).read()
starts = [float(x) for x in re.findall(r"silence_start: ([\d.]+)", text)]
ends = [float(x) for x in re.findall(r"silence_end: ([\d.]+)", text)]
dur = float(subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration",
                            "-of", "csv=p=0", src], capture_output=True, text=True).stdout)
# A voice line runs from the end of one silence to the start of the next.
if not starts or starts[0] > 0.05:
    ends.insert(0, 0.0)
starts = [s for s in starts if s > 0.05] + [dur]
n = 0
for s, e in zip(ends, starts):
    if e - s < 0.2:
        continue
    n += 1
    s0 = max(0.0, s - 0.05)
    length = e + 0.1 - s0
    subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-ss", f"{s0:.3f}",
                    "-t", f"{length:.3f}", "-i", src,
                    "-af", f"afade=t=out:st={length - 0.1:.3f}:d=0.1", f"{out}/{n:02d}.mp3"], check=True)
print(f"{n} clips in {out}/  listen, delete the ones you dont like, then run ./install.sh")
PY
