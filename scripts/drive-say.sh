#!/usr/bin/env bash
#
# drive-say.sh - Text-to-speech via ElevenLabs
#
# Usage: ./drive-say.sh "message to speak"
#        ./drive-say.sh --voice VOICE_ID "message"
#        ./drive-say.sh --model MODEL_ID "message"
#
# Environment:
#   ELEVENLABS_API_KEY   (required) API key from elevenlabs.io
#   ELEVENLABS_VOICE_ID  (optional) Voice ID, defaults to Lily
#   ELEVENLABS_MODEL     (optional) Model ID, defaults to eleven_turbo_v2
#
# Requires: curl, afplay (macOS) or mpv/aplay (Linux)
#
set -euo pipefail

# --- Dependency check ---

for cmd in curl; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "Error: Required command '$cmd' not found." >&2
    exit 1
  fi
done

detect_player() {
  if command -v afplay &>/dev/null; then
    echo "afplay"
  elif command -v mpv &>/dev/null; then
    echo "mpv --no-terminal"
  elif command -v aplay &>/dev/null; then
    echo "aplay"
  else
    echo ""
  fi
}

PLAYER=$(detect_player)
if [ -z "$PLAYER" ]; then
  echo "Error: No audio player found. Install afplay (macOS), mpv, or aplay." >&2
  exit 1
fi

# --- Configuration ---

ELEVENLABS_API_KEY="${ELEVENLABS_API_KEY:?Error: ELEVENLABS_API_KEY environment variable is not set}"
VOICE_ID="${ELEVENLABS_VOICE_ID:-pFZP5JQG7iQjIQuC4Bku}"  # Lily
MODEL="${ELEVENLABS_MODEL:-eleven_turbo_v2}"
LOCK="/tmp/drive-say.lock"

# --- Argument parsing ---

while [[ $# -gt 0 ]]; do
  case "$1" in
    --voice)   shift; VOICE_ID="$1"; shift ;;
    --voice=*) VOICE_ID="${1#--voice=}"; shift ;;
    --model)   shift; MODEL="$1"; shift ;;
    --model=*) MODEL="${1#--model=}"; shift ;;
    --help|-h)
      sed -n '3,/^$/p' "$0" | sed 's/^# \?//'
      exit 0
      ;;
    -*)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
    *)
      TEXT="$1"
      shift
      ;;
  esac
done

if [ -z "${TEXT:-}" ]; then
  echo "Error: No message provided." >&2
  echo "Usage: drive-say.sh \"message to speak\"" >&2
  exit 1
fi

# --- Cleanup ---

OUT="/tmp/drive-speech-$$.mp3"

cleanup() {
  rm -f "$OUT" "$LOCK"
}
trap cleanup EXIT INT TERM

# --- Wait for previous speech ---

WAIT_COUNT=0
while [ -f "$LOCK" ]; do
  sleep 0.5
  WAIT_COUNT=$((WAIT_COUNT + 1))
  if [ "$WAIT_COUNT" -ge 60 ]; then
    echo "Warning: Lock file stale after 30s, removing." >&2
    rm -f "$LOCK"
    break
  fi
done

touch "$LOCK"

# --- Build payload and call API ---

PAYLOAD=$(python3 -c "
import json, sys
print(json.dumps({
    'text': sys.argv[1],
    'model_id': sys.argv[2]
}))
" "$TEXT" "$MODEL")

HTTP_CODE=$(curl -s -w '%{http_code}' \
  "https://api.elevenlabs.io/v1/text-to-speech/$VOICE_ID" \
  -H "xi-api-key: $ELEVENLABS_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" \
  --output "$OUT" \
  --max-time 30) || {
    echo "Error: Failed to connect to ElevenLabs API." >&2
    exit 1
  }

if [ "$HTTP_CODE" -eq 401 ]; then
  echo "Error: HTTP 401 — invalid ELEVENLABS_API_KEY." >&2
  exit 1
elif [ "$HTTP_CODE" -eq 422 ]; then
  echo "Error: HTTP 422 — invalid voice ID or model." >&2
  exit 1
elif [ "$HTTP_CODE" -ge 400 ]; then
  echo "Error: ElevenLabs API returned HTTP $HTTP_CODE." >&2
  exit 1
fi

# --- Play audio ---

$PLAYER "$OUT"
