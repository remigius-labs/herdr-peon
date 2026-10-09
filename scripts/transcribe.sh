#!/bin/sh
# Write down what each clip says, locally with Whisper. Output: <clips>/transcript.tsv (file, seconds, text).
set -eu
here=$(cd "$(dirname "$0")" && pwd)
clips="${1:-${XDG_DATA_HOME:-$HOME/.local/share}/herdr-peon/clips}"
venv="${XDG_DATA_HOME:-$HOME/.local/share}/herdr-peon/venv"
if [ ! -x "$venv/bin/python" ]; then
  python3 -m venv "$venv"
  "$venv/bin/pip" install -q faster-whisper
fi
"$venv/bin/python" - "$clips" <<'PY'
import glob, os, subprocess, sys
import numpy as np
from faster_whisper import WhisperModel
clips = sys.argv[1]
model = WhisperModel("small.en", device="cpu", compute_type="int8")
rows = []
for f in sorted(glob.glob(os.path.join(clips, "*.mp3"))):
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", f, "-f", "s16le", "-ac", "1", "-ar", "16000", "-"],
                         capture_output=True, check=True).stdout
    audio = np.frombuffer(raw, np.int16).astype(np.float32) / 32768
    segs, _ = model.transcribe(audio, beam_size=5, language="en",
                               initial_prompt="Warcraft III unit voice lines.")
    text = " ".join(s.text.strip() for s in segs)
    rows.append(f"{os.path.basename(f)}\t{len(audio) / 16000:.2f}\t{text}")
    print(rows[-1])
open(os.path.join(clips, "transcript.tsv"), "w").write("\n".join(rows) + "\n")
print(f"{len(rows)} lines in {clips}/transcript.tsv  next: sort them into ack/, request/, done/, annoyed/")
PY
