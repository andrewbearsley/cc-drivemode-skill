#!/bin/bash
# TaskCompleted hook — play a soft tone when a background task finishes,
# gated on drive-mode being active and not self-triggered by drive-mode's own audio.

[ -f /tmp/drive-mode.active ] || exit 0

CMD=$(jq -r '.tool_input.command // empty' 2>/dev/null)

# Skip drive-mode's own audio tasks (speak script, direct afplay).
if echo "$CMD" | grep -qE 'drive-mode/speak|afplay /System/Library/Sounds'; then
  exit 0
fi

afplay /System/Library/Sounds/Pop.aiff 2>/dev/null || true
