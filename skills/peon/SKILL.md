---
name: peon
description: Turn a Warcraft III unit voice-line video into Herdr agent sounds - "Work, work" when you give an order, "Something need doing?" when an agent needs you, "Job's done!" when it finishes. Use when the user types /peon, pastes a voice-line video for Herdr, or wants to swap or set up unit voices.
argument-hint: <youtube-url of a Warcraft III unit voice-line compilation>
allowed-tools: [Bash, Read]
---

# Peon

Set up Warcraft III unit voices for every agent Herdr runs. The user brings a video and pastes two commands you write for them; you do the rest. Short messages, no jargon.

The plugin keeps a stable link to itself at `~/.local/share/herdr-peon/plugin/` (refreshed on every prompt). Working files go in `~/.local/share/herdr-peon/clips/`. You only read files; every command that changes the user's system is a line you hand them with `!`.

## 1. Check the machine (silently, report only what is missing)

Needs `herdr`, `ffmpeg`, `yt-dlp`, `python3`, and one of `pw-play`/`paplay`. If something is missing, name it and the install command for their system (Arch: `sudo pacman -S ffmpeg yt-dlp`), then stop until they confirm.

## 2. Get the video

Use the argument if given. Otherwise ask once: "Paste a YouTube link to a Warcraft III unit's voice lines (search 'warcraft 3 peon quotes', 'peasant quotes', 'grunt quotes')." Only Warcraft III units.

## 3. Hand the first command to the user

Downloading, installing the speech model and writing to their home folder happen in the user's own shell, not through your tools: sandboxes and auto-mode checks rightly stop an agent from installing software. Give them exactly one line to paste (the `!` prefix runs it in their shell):

```
! sh ~/.local/share/herdr-peon/plugin/scripts/prepare.sh "<url>"
```

Say it downloads a speech model once (about 500 MB) and runs on their machine; nothing is uploaded. Wait until they say it finished.

## 4. Sort the lines yourself

Read `~/.local/share/herdr-peon/clips/transcript.tsv` (file, seconds, text). Warcraft III units have three kinds of lines, and they map onto agents:

| Bucket | In the game | For agents | Examples |
|---|---|---|---|
| `ack` | the unit takes an order | agent starts: first prompt of a session | Work, work · Okie dokie · As you wish · I can do that · Be happy to |
| `request` | you click the unit | agent needs you | Yes? · What you want? · Something need doing? · My lord? · Hm? |
| `done` | the unit is ready | agent is done | Ready to work · Job's done! · Dabu · Ready to serve |
| `annoyed` | you click it too often | kept aside, never played | Me busy, leave me alone! · Me not that kind of orc |

Whisper mishears accents ("Be happy too", "Adam" for "Dabu"); judge by what the line means. Leave out clips that are noise, music, two lines run together, or unclear. Aim for at least two lines in each of `ack`, `request`, `done`.

Show the user one compact table (line, bucket) and ask a single question: "Good? (yes, or tell me what to move)". Apply any moves they ask for.

## 5. Hand the install command to the user

Write the install line with your sort baked in, clip numbers from the transcript, and give it to them to paste:

```
! sh ~/.local/share/herdr-peon/plugin/scripts/install-sounds.sh ack=05,06 request=03,04,08 done=07,09 annoyed=14,15
```

It files each clip under a name from its words, replaces the unit in `~/.config/herdr/sounds/` (the previous unit moves to `previous/`), points Herdr's done and needs-you sounds at them (backing up `config.toml` to `config.toml.bak-peon`), starts a one-minute shuffle timer so every ping is a new line for every agent, and reloads Herdr.

## 6. Let them hear it

Give them one more line to paste, so they hear each sound once:

```
! for b in ack request done; do pw-play "$(ls ~/.config/herdr/sounds/$b/*.mp3 | shuf -n1)"; sleep 1; done
```

(`paplay` instead of `pw-play` on PulseAudio.) Then say, in one or two lines: Herdr now speaks when an agent in another workspace needs them or finishes, and Claude sessions get an order line on their first prompt. To swap units, run `/peon` again with a new video.
