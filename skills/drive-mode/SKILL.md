---
name: drive-mode
description: Hands-free audio feedback for Claude Code — announces task progress aloud via ElevenLabs TTS so you can step away from the screen.
version: 1.0.0
homepage: https://github.com/andrewbearsley/cc-drivemode-skill
metadata: {"openclaw": {"requires": {"bins": ["curl", "python3"], "env": ["ELEVENLABS_API_KEY"]}, "primaryEnv": "ELEVENLABS_API_KEY"}}
---

# Drive Mode Skill

Announce task progress aloud using ElevenLabs text-to-speech. When the user activates drive mode, you speak status updates so they can work hands-free.

**Script paths:** All `scripts/` paths below are relative to the skill's install directory. If installed via the agent quick-start, that's `~/.openclaw/skills/drive-mode/scripts/`. Adjust paths based on where you installed the skill.

---

## Activation

Drive mode activates when the user says **"drive mode"** or **"speak results"**. Once active, announce progress aloud for the remainder of the conversation.

---

## How to Speak

Run the TTS script in the background so work continues while speaking:

```bash
scripts/drive-say.sh "message" &
```

Or from Claude Code, use the Bash tool with `run_in_background=true`:

```bash
scripts/drive-say.sh "Build complete. All 47 tests passed."
```

**Always run TTS in the background.** Never block on speech output.

---

## What to Announce

Announce at natural milestones:

- **Task started:** Brief description of what you're about to do
- **Significant progress:** 25%, 50%, 75% milestones for long-running tasks
- **Completion:** Result summary — what was done, whether it succeeded
- **Errors or blockers:** Anything that changes the plan
- **Answers to questions:** When the user asked something and you have the answer

Do NOT announce:
- Routine file reads or searches
- Individual tool calls
- TTS completion confirmations

---

## Conciseness Rules

Every second of voice time must carry information. Be direct.

**Good:**
- "Fees included. 0.1% per side, 0.05% slippage. All numbers are net."
- "Build failed. Missing import in auth service line 42. Fixing now."
- "Deploy complete. All pods healthy."

**Bad:**
- "Great question. Let me look at the fee configuration for those backtests. So looking at the transaction cost config..."
- "Alright, I've finished looking at the build output and it seems like there might be an issue..."

Lead with the answer. Skip preamble, filler, and "let me check" phrases.

---

## Long-Running Task Monitoring

For tasks that take more than a couple of minutes (builds, deploys, large refactors), create a background monitor:

### Pattern

1. Create a shell script that polls task status
2. Run it in the background with `run_in_background=true`
3. Use touch files to prevent duplicate announcements

### Example monitor script

```bash
#!/usr/bin/env bash
TASK_NAME="$1"
SAY="$2"  # path to drive-say.sh

while true; do
  # Check task status (replace with actual check)
  STATUS=$(check_status_command)

  if [ "$STATUS" = "25%" ] && [ ! -f "/tmp/task-25" ]; then
    touch /tmp/task-25
    "$SAY" "$TASK_NAME is 25% complete." &
  fi

  if [ "$STATUS" = "complete" ]; then
    "$SAY" "$TASK_NAME finished successfully." &
    rm -f /tmp/task-25 /tmp/task-50 /tmp/task-75
    exit 0
  fi

  sleep 120
done
```

### Touch file convention

- Path: `/tmp/task-{milestone}` (e.g., `/tmp/task-25`, `/tmp/task-50`)
- Create the file when announcing a milestone
- Clean up all touch files when the task completes or fails
- This prevents the same milestone from being announced twice

---

## Etiquette

- **Do NOT acknowledge TTS completions in text.** When the background speech finishes, ignore it silently. Do not write "voice done" or "background command completed."
- **Do NOT report TTS status.** Just continue working.
- **Mention voice issues only if TTS actually fails.** If the script returns an error, say so once and continue without voice.
- The lock file (`/tmp/drive-say.lock`) prevents overlapping speech automatically — no need to manage this yourself.

---

## Configuration

The script supports these environment variables:

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `ELEVENLABS_API_KEY` | Yes | — | API key from [elevenlabs.io](https://elevenlabs.io) |
| `ELEVENLABS_VOICE_ID` | No | `pFZP5JQG7iQjIQuC4Bku` (Lily) | Voice to use for speech |
| `ELEVENLABS_MODEL` | No | `eleven_turbo_v2` | TTS model (turbo is fastest) |

You can also override per-call:

```bash
scripts/drive-say.sh --voice OTHER_VOICE_ID "message"
scripts/drive-say.sh --model eleven_multilingual_v2 "message"
```

### Choosing a voice

Lily (the default) is a British female voice with a warm, velvety tone. The user can change this by setting `ELEVENLABS_VOICE_ID` to any voice from the [ElevenLabs voice library](https://elevenlabs.io/voice-library).

---

## Error Handling

| Error | What to do |
|-------|------------|
| `ELEVENLABS_API_KEY not set` | Ask the user to set the environment variable |
| HTTP 401 | API key is invalid — ask the user to check it |
| HTTP 422 | Voice ID or model is invalid — check configuration |
| HTTP 429 | Rate limited — skip this announcement, try again next milestone |
| Network error / timeout | Skip silently, continue working |
| No audio player found | Inform user once, suggest installing `afplay` (macOS) or `mpv` (Linux) |

If TTS fails, **do not retry in a loop**. Note it once and continue working without voice.

---

## Script Reference

### `scripts/drive-say.sh`

Text-to-speech via ElevenLabs. Plays audio through the system speaker.

```bash
# Basic usage
scripts/drive-say.sh "Deploy complete. All pods healthy."

# Custom voice
scripts/drive-say.sh --voice JBFqnCBsd6RMkjVDRZzb "Build started."

# Custom model (for multilingual)
scripts/drive-say.sh --model eleven_multilingual_v2 "Terminé."

# Background (recommended)
scripts/drive-say.sh "Pipeline running." &
```

**Behaviour:**
- Waits for any previous speech to finish (lock file)
- Calls ElevenLabs API, downloads audio
- Plays through system speaker
- Cleans up temp files on exit

**Exit codes:**
- `0` — success
- `1` — error (missing deps, API failure, no audio player)

---

## Tips

- The `eleven_turbo_v2` model has the lowest latency. Use it unless you need multilingual support.
- Keep messages under ~30 words for natural speech. Split longer updates into separate calls if needed.
- On macOS, `afplay` is built in. On Linux, install `mpv` (`apt install mpv` or `brew install mpv`).
- The lock file times out after 30 seconds to recover from crashes.
- Python 3 is required only for JSON payload construction (no pip packages needed).
