---
name: drive-mode
description: Enable hands-free progress announcements via text-to-speech. Use when the user says "drive mode", "speak results", or otherwise indicates they cannot see the screen and need audio updates.
user_invocable: true
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/skills/drive-mode/speak *) Bash(touch /tmp/drive-mode.active) Bash(rm -f /tmp/drive-mode.active)
---

# Drive Mode

The user cannot see the screen. Every meaningful response MUST be spoken aloud via the bundled script. Text-only replies are useless in drive mode.

## Arguments

- `/drive-mode` or `/drive-mode on` — activate
- `/drive-mode off` — deactivate
- Also activate if the user says "drive mode" / "speak results" in prose; deactivate if they say "drive mode off" / "stop speaking" / "exit drive mode"

## Activation

```bash
touch /tmp/drive-mode.active
${CLAUDE_PLUGIN_ROOT}/skills/drive-mode/speak "Drive mode on."
```

The flag file `/tmp/drive-mode.active` enables bundled hooks:
- **Stop** — soft Morse tone at end of turn, cueing you're waiting for input
- **Notification** — brighter Glass tone when Claude is blocked on a permission prompt
- **TaskCompleted** — short Pop tone when a background task finishes (ignores the speak script and afplay so drive-mode's own audio doesn't self-trigger)
- **UserPromptSubmit** — kills any in-flight `say`/`afplay` and clears the lock, so a new prompt doesn't collide with leftover audio
- **SessionStart** — clears the flag on session start so a crashed-out flag doesn't carry over silently

## Deactivation

```bash
rm -f /tmp/drive-mode.active
```

Silent end — don't speak the exit.

## Speaking

Always use the bundled script. Never call `say` directly:

```bash
${CLAUDE_PLUGIN_ROOT}/skills/drive-mode/speak "text to announce"
```

Run with `run_in_background=true`. The script serializes concurrent calls via an atomic `mkdir` lock so rapid calls queue in order instead of overlapping.

Voice: tries ElevenLabs (Lily) if `ELEVENLABS_API_KEY` is set, otherwise `say` with the system default voice from System Settings > Accessibility > Spoken Content.

## What to announce

MANDATORY in drive mode — speak every meaningful response:

- Conclusions and findings — what you learned, what broke, what passed
- Decisions and recommendations — what you'd do and why
- Questions — anything you're waiting on the user for
- Plans — what you're about to do, before doing it, if the user needs to weigh in
- Major state changes — tests passing, deploy finished, errors thrown

Rule of thumb: if you wrote text to the user, you should also have spoken the key point of it.

## What NOT to announce

- Every tool call or intermediate step
- File paths, long identifiers, raw shell output, code snippets
- Pure status noise ("Okay", "Done", "Got it")
- Repetition of what was just said a moment ago

## Style

- One or two sentences per call. Every second of voice carries information.
- Plain prose, no markdown, no code fences, no emojis, no backticks.
- Pronounce-friendly: skip punctuation-heavy strings; spell out ambiguous acronyms.
- Do NOT acknowledge TTS completions ("Spoken." / "Said that.") in follow-up text.

## Troubleshooting

- Nothing heard: `echo $ELEVENLABS_API_KEY`. Empty means `say` path — check system volume.
- Overlapping audio: shouldn't happen; if it does, check `ls /tmp/drive-mode.lock.d` and `rm -rf` it to unstick.
- No end-of-turn tone: verify `/tmp/drive-mode.active` exists and the plugin's hooks are active (open `/hooks` to inspect).
- Override voice: `DRIVE_MODE_VOICE` (say name) or `DRIVE_MODE_EL_VOICE` (ElevenLabs voice ID).
