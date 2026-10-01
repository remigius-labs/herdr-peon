# herdr-peon

Your [Herdr](https://herdr.dev) agents ping you with Warcraft III peon voice lines instead of a bling. A random line every time.

*"Something need doing?"*

## How it works

- Herdr plays one sound file when a background agent finishes or needs you. That file is a symlink.
- A Claude Code `UserPromptSubmit` hook re-points the symlink at a random clip on every prompt, so the next ping is a different line.

## Install

Needs `herdr`, `yt-dlp`, `ffmpeg`, `python3`.

```bash
git clone https://github.com/remigius-labs/herdr-peon && cd herdr-peon
./get-clips.sh "<youtube url of a peon voice line compilation>"
# listen to clips/, delete the ones you dont like
./install.sh
```

`get-clips.sh` downloads the audio and cuts it into one mp3 per line, split on silence. Works with any voice line compilation: peasants, grunts, Arthas, whoever.

`install.sh` copies the clips to `~/.config/herdr/sounds/peon/`, adds `[ui.sound]` to your Herdr config, adds the hook to `~/.claude/settings.json` (backup first) and reloads Herdr. Safe to re-run.

## Limits

- Herdr only plays sounds for agents in workspaces you are not looking at.
- The shuffle runs per prompt, so pings within one turn repeat the same line.
- No audio ships with this repo. The voice lines belong to Blizzard; you bring your own.

## License

MIT, scripts only.
