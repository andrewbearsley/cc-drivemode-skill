# Drive Mode — Claude Code Plugin

![Plugin](https://img.shields.io/badge/format-Claude%20Code%20Plugin-blue)
![Version](https://img.shields.io/badge/version-2.0.0-green)
![License](https://img.shields.io/github/license/andrewbearsley/cc-drivemode-skill)

Hands-free audio feedback for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Say "drive mode" and Claude announces findings, questions, and conclusions aloud, plays tones at key moments (end of turn, blocked on permission, background task complete), and kills in-flight audio when you submit a new prompt.

Built for moments when you're driving, cooking, or otherwise can't look at the screen.

## What it does

| Event | Behavior |
|-------|----------|
| Claude makes a finding or asks a question | Speaks it via `say` (or ElevenLabs if configured) |
| Claude finishes its turn | Soft **Morse** tone — "I'm waiting for you" |
| Claude is blocked on a permission prompt | Brighter **Glass** tone — "pull over and look" |
| A background task finishes | Short **Pop** tone — "something completed" |
| You submit a new prompt | Kills any in-flight speech — your new input doesn't collide with stale audio |
| Session starts | Clears stale flag file so a crashed-out session doesn't keep playing tones |

## Requirements

- macOS (uses built-in `say` and `afplay`)
- Claude Code 2.x or newer with plugin support

ElevenLabs is optional — if `ELEVENLABS_API_KEY` is set in your environment, the speak script routes through ElevenLabs (Lily voice by default) for more natural TTS. Otherwise it falls back to macOS `say` using whatever voice you've set in System Settings > Accessibility > Spoken Content.

Tip: to hear the best quality from `say`, install a Siri or Premium voice via System Settings > Accessibility > Spoken Content > System Voice > Manage Voices.

## Installation

### Via Claude Code plugin install

```bash
claude plugin install drive-mode@github:andrewbearsley/cc-drivemode-skill
```

### Manual / local install (development)

Clone the repo and point Claude Code at it:

```bash
git clone https://github.com/andrewbearsley/cc-drivemode-skill.git
cd cc-drivemode-skill
# Then use Claude Code's plugin install with a file:// source,
# or symlink into ~/.claude/plugins/ (structure may vary by CC version).
```

After installing, restart Claude Code or open `/hooks` once to make the settings watcher pick up the bundled hooks.

## Usage

Just say it:

> "drive mode"

Or use the slash command:

```
/drive-mode
/drive-mode on
/drive-mode off
```

Drive mode stays on for the current session. A `SessionStart` hook clears it on new sessions — activate explicitly each time.

## How it works

```
cc-drivemode-skill/
├── .claude-plugin/
│   └── plugin.json           # plugin manifest
├── skills/
│   └── drive-mode/
│       ├── SKILL.md          # behaviour instructions for Claude
│       └── speak             # TTS wrapper (ElevenLabs with `say` fallback)
├── hooks/
│   └── hooks.json            # Stop, Notification, TaskCompleted, UserPromptSubmit, SessionStart
├── scripts/
│   └── task-complete.sh      # filter for TaskCompleted hook (ignores self-triggers)
├── README.md
└── LICENSE
```

The plugin gates every hook on `/tmp/drive-mode.active` — so the tones only fire when drive mode is explicitly on. Activation touches the file, deactivation removes it.

Concurrent `speak` calls are serialized via an atomic `mkdir` lock at `/tmp/drive-mode.lock.d`, so rapid calls queue in order rather than overlapping. (`flock` isn't available on macOS.)

## ElevenLabs (optional)

Copy `.env.example` and set your key:

```bash
export ELEVENLABS_API_KEY=your_key_here
```

Override voice:

```bash
export DRIVE_MODE_EL_VOICE=pFZP5JQG7iQjIQuC4Bku   # Lily (default)
```

Browse voices at [elevenlabs.io/voice-library](https://elevenlabs.io/voice-library).

## Sounds

| Hook | File | Character |
|------|------|-----------|
| Stop | `/System/Library/Sounds/Morse.aiff` | Soft, short — end of turn |
| Notification | `/System/Library/Sounds/Glass.aiff` | Brighter — needs your attention |
| TaskCompleted | `/System/Library/Sounds/Pop.aiff` | Very short — something finished |

Swap any of these in `hooks/hooks.json` to taste.

## Troubleshooting

| Problem | Fix |
|---------|-----|
| No audio at all | Check volume; confirm `/tmp/drive-mode.active` exists; `say "test"` works? |
| Speech overlaps | Stale lock — `rm -rf /tmp/drive-mode.lock.d` |
| Hooks don't fire after install | Open `/hooks` once in Claude Code, or restart the session (settings watcher needs to reload) |
| ElevenLabs silent | Check `echo $ELEVENLABS_API_KEY`; HTTP errors are logged to stderr |
| Speech robotic | Install a Premium or Siri voice via System Settings |

## License

MIT — see [LICENSE](LICENSE).
