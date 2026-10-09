# herdr-peon

Your [Herdr](https://herdr.dev) agents talk like the Warcraft III Peon. "Work, work" when you give an order, "Something need doing?" when an agent needs you, "Ready to work" when it finishes.

Made for the Peon. Other Warcraft III units work too.

A Claude Code plugin. You paste a link to a unit's voice lines; Claude cuts the video into lines, listens to each one, sorts them and sets up Herdr. Works for every agent Herdr runs.

## Install

```
/plugin marketplace add remigius-labs/herdr-peon
/plugin install herdr-peon@herdr-peon
```

Then in Claude Code:

```
/peon <youtube link to "warcraft 3 peon quotes">
```

Run `/peon` again with another video to swap units.

## Units

Search YouTube for "warcraft 3 peon quotes" and paste the link. That is the one this was made for.

Other units, same search with their name:

- **Peasant** (tested): "Yes, milord?" · "Off I go then" · "Job's done!"
- Should work, not tested yet: Grunt, Footman, Knight, Death Knight, or any Warcraft III unit with a voice-line compilation. Clear, one-line-at-a-time videos sort best.

## The three sounds

| When | Peon says | In the game |
|---|---|---|
| **Agent starts**: your first message to a new Claude session | "Work, work" · "Okie dokie" · "Be happy to" | the unit takes an order |
| **Agent needs you**: waiting on an answer or an approval | "Something need doing?" · "What you want?" · "Yes?" | you click the unit |
| **Agent is done**: finished its work | "Ready to work" · "Okay" · "Dabu" | the unit is ready |

The annoyed lines ("Me busy, leave me alone!") are kept aside and never played. A new line is picked each time, so it stays fresh.

## What happens

1. The video is downloaded and cut into one clip per line (`yt-dlp`, `ffmpeg`).
2. Whisper writes down what each clip says, on your machine.
3. Claude sorts the lines into the three sounds above.
4. Herdr's sounds point at the clips, and a small timer shuffles them every minute so each ping is a new line.

## Needs

Herdr, Claude Code, `ffmpeg`, `yt-dlp`, `python3`, PipeWire or PulseAudio. The first run downloads a speech model (about 500 MB).

## Limits

- Herdr plays sounds only for agents in workspaces you are not looking at.
- The order line on a new session works in Claude Code only; the other sounds work for every agent.
- No audio ships with this plugin. The voice lines belong to Blizzard Entertainment; you fetch them yourself, on your machine, for personal use.
- Linux only (systemd user timer).

## Remove

```
/plugin uninstall herdr-peon
systemctl --user disable --now herdr-peon-shuffle.timer
```

Restore Herdr's sound settings from `~/.config/herdr/config.toml.bak-peon`.

## License

MIT, scripts only. Fan project, not affiliated with or endorsed by Blizzard Entertainment. Warcraft is a trademark of Blizzard Entertainment.
