---
name: peon
description: Turn a Warcraft III unit voice-line video into Herdr agent sounds - "Work, work" when you give an order, "Something need doing?" when an agent needs you, "Job's done!" when it finishes. Use when the user types /peon, pastes a voice-line video for Herdr, or wants to swap or set up unit voices.
argument-hint: <youtube-url of a Warcraft III unit voice-line compilation>
allowed-tools: [Bash, Read]
---

# Peon

Set up Warcraft III unit voices for every agent Herdr runs. The user pastes a link; you do the rest without asking anything. Short messages, no jargon.

The plugin keeps a stable link to itself at `~/.local/share/herdr-peon/plugin/` (refreshed on every prompt). Working files go in `~/.local/share/herdr-peon/clips/`. Run the scripts yourself; only when a sandbox or auto-mode check blocks one, hand the user that line with `!`.

## 1. Check the machine (silently, report only what is missing)

Needs `herdr`, `ffmpeg`, `yt-dlp`, `python3`, and one of `pw-play`/`paplay`. If something is missing, name it and the install command for their system (Arch: `sudo pacman -S ffmpeg yt-dlp`), then stop until they confirm.

## 2. Get the video

Use the argument if given. Otherwise ask once: "Paste a YouTube link to a Warcraft III unit's voice lines (search 'warcraft 3 peon quotes', 'peasant quotes', 'grunt quotes')." Only Warcraft III units.

## 3. Cut and transcribe

Say in one line that it downloads a speech model once (about 500 MB) and runs on their machine, nothing uploaded. Then run it yourself:

```bash
sh ~/.local/share/herdr-peon/plugin/scripts/prepare.sh "<url>"
```

It writes outside the project (`~/.local/share/herdr-peon`, later `~/.config/herdr`) and downloads software, so a sandbox may block it. If the sandbox blocks it, run it again with the sandbox turned off for that one command; the user gets one approval prompt. Only if that is refused or an auto-mode check blocks it, do not work around it: hand the user the same command to paste, with the `!` prefix so it runs in their own shell, and wait until they say it finished:

```
! sh ~/.local/share/herdr-peon/plugin/scripts/prepare.sh "<url>"
```

## 4. Sort the lines yourself

Read `~/.local/share/herdr-peon/clips/transcript.tsv` (file, seconds, text). Warcraft III units have three kinds of lines, and they map onto agents:

| Bucket | In the game | For agents | Examples |
|---|---|---|---|
| `ack` | the unit takes an order | agent starts: first prompt of a session | Work, work · Okie dokie · As you wish · I can do that · Be happy to |
| `request` | you click the unit | agent needs you | Yes? · What you want? · Something need doing? · My lord? · Hm? |
| `done` | the unit is ready | agent is done | Ready to work · Job's done! · Dabu · Ready to serve |
| `annoyed` | you click it too often | kept aside, never played | Me busy, leave me alone! · Me not that kind of orc |

Whisper mishears accents ("Be happy too", "Adam" for "Dabu"); judge by what the line means. Leave out clips that are noise, music, two lines run together, or unclear. Aim for at least two lines in each of `ack`, `request`, `done`.

Do not ask before installing; go straight to step 5.

## 5. Install

Run the install with your sort baked in: clip number, a colon, and the real words as a short name (fix Whisper's mishearings here, "Adam" is `dabu`):

```bash
sh ~/.local/share/herdr-peon/plugin/scripts/install-sounds.sh ack=05:work-work,06:okie-dokie request=03:something-need-doing,04:what-you-want done=07:ready-to-work,11:dabu annoyed=14:me-busy
```

If it is blocked, handle it as in step 3.

It files each clip under a name from its words, replaces the unit in `~/.config/herdr/sounds/` (the previous unit moves to `previous/`), points Herdr's done and needs-you sounds at them (backing up `config.toml` to `config.toml.bak-peon`), starts a one-minute shuffle timer so every ping is a new line for every agent, and reloads Herdr.

## 6. Let them hear it

Show one compact table of what went where (line, sound), then play one line from each sound, a second apart:

```bash
for b in ack request done; do pw-play "$(ls ~/.config/herdr/sounds/$b/*.mp3 | shuf -n1)"; sleep 1; done
```

(`paplay` instead of `pw-play` on PulseAudio.) If they want a line moved, run the install again with the new sort (the clips are still in `~/.local/share/herdr-peon/clips/`, sorted into folders: move the file between folders and run `install-sounds.sh` with no arguments). Then say, in one or two lines: Herdr now speaks when an agent in another workspace needs them or finishes, and Claude sessions get an order line on their first prompt. To swap units, run `/peon` again with a new video.
