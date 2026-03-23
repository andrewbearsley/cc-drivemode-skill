# Drive Mode for Claude Code

![Format](https://img.shields.io/badge/format-Agent%20Skill-blue)
![Bash](https://img.shields.io/badge/bash-%23121011?logo=gnu-bash&logoColor=white)
![License](https://img.shields.io/github/license/andrewbearsley/cc-drivemode-skill)

Hands-free audio feedback for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Say "drive mode" and Claude announces task progress aloud via [ElevenLabs](https://elevenlabs.io) text-to-speech — so you can step away from the screen and still know what's happening.

## Agent quick-start

If you're an AI agent and your user has pointed you at this repo, here's how to install the skill without cloning.

**Requirements:** `curl`, `python3` must be available on the system. An audio player is needed: `afplay` (macOS, built-in) or `mpv` / `aplay` (Linux).

**1. Download the skill and scripts:**

```bash
REPO="https://raw.githubusercontent.com/andrewbearsley/cc-drivemode-skill/main"
SKILL_DIR="$HOME/.openclaw/skills/drive-mode"
SCRIPT_DIR="$SKILL_DIR/scripts"

mkdir -p "$SCRIPT_DIR"
curl -fsSL "$REPO/skills/drive-mode/SKILL.md" -o "$SKILL_DIR/SKILL.md"
curl -fsSL "$REPO/scripts/drive-say.sh" -o "$SCRIPT_DIR/drive-say.sh"
chmod +x "$SCRIPT_DIR"/*.sh
```

**2. Set environment variables:**

The skill requires one environment variable. Ask your user for this if they haven't provided it:

| Variable | Required | What it is | Where to find it |
|----------|----------|-----------|-----------------|
| `ELEVENLABS_API_KEY` | Yes | API key | [elevenlabs.io](https://elevenlabs.io) > Profile > API Keys |
| `ELEVENLABS_VOICE_ID` | No | Voice to use | Defaults to Lily (British female). Browse [voice library](https://elevenlabs.io/voice-library) |
| `ELEVENLABS_MODEL` | No | TTS model | Defaults to `eleven_turbo_v2` (fastest) |

Set it in `~/.openclaw/.env` or in your agent's environment.

**3. Verify it works:**

```bash
$SCRIPT_DIR/drive-say.sh "Drive mode is active."
```

**4. Read the SKILL.md** for full behaviour instructions, conciseness rules, and monitoring patterns.

## What it does

- Speaks task progress aloud so you can work hands-free
- Queues speech with a lock file to prevent overlapping audio
- Monitors long-running tasks and announces milestones (25/50/75/100%)
- Uses touch files to prevent duplicate announcements
- Stays concise — every second of voice carries information

## Human setup

You'll need to do these steps before the agent can use the skill.

### 1. Get an ElevenLabs API key

1. Sign up at [elevenlabs.io](https://elevenlabs.io)
2. Go to **Profile** > **API Keys**
3. Create and copy your key

The free tier includes a generous amount of characters per month. Paid plans offer more.

### 2. Give your agent the credentials

Add the environment variable to `~/.openclaw/.env`:

```
ELEVENLABS_API_KEY=your_api_key_here
```

Then point your agent at this repo and ask it to install the skill.

### 3. (Optional) Pick a voice

The default voice is **Lily** — a British female with a warm, velvety tone. To use a different voice:

1. Browse the [ElevenLabs voice library](https://elevenlabs.io/voice-library)
2. Copy the voice ID
3. Set `ELEVENLABS_VOICE_ID` in your environment

## Usage

Once installed, just tell Claude Code:

> "drive mode"

or

> "speak results"

Claude will start announcing progress aloud. That's it.

### Manual script usage

```bash
# Basic
./scripts/drive-say.sh "Deploy complete. All pods healthy."

# Custom voice
./scripts/drive-say.sh --voice JBFqnCBsd6RMkjVDRZzb "Build started."

# Custom model (multilingual)
./scripts/drive-say.sh --model eleven_multilingual_v2 "Terminé."
```

## Platform support

| Platform | Audio player | Status |
|----------|-------------|--------|
| macOS | `afplay` (built-in) | Fully supported |
| Linux | `mpv` or `aplay` | Supported (install `mpv` via package manager) |
| Windows/WSL | `mpv` | Untested |

## Troubleshooting

| Problem | What's going on | Fix |
|---------|-----------------|-----|
| "ELEVENLABS_API_KEY not set" | Env var not loaded | Set `ELEVENLABS_API_KEY` in the environment |
| HTTP 401 | API key is invalid | Generate a new key at elevenlabs.io |
| HTTP 422 | Bad voice ID or model | Check `ELEVENLABS_VOICE_ID` and `ELEVENLABS_MODEL` values |
| No audio player found | Missing `afplay`/`mpv`/`aplay` | macOS has `afplay` built in; on Linux install `mpv` |
| Overlapping speech | Lock file stuck | Delete `/tmp/drive-say.lock` manually (auto-clears after 30s) |
| No sound | Volume muted or wrong output device | Check system audio settings |

## Files

| File | Purpose |
|------|---------|
| `skills/drive-mode/SKILL.md` | Skill definition: agent behaviour instructions, configuration, monitoring patterns |
| `scripts/drive-say.sh` | TTS wrapper: calls ElevenLabs API and plays audio |

## License

MIT
