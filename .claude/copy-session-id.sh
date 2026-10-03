#!/usr/bin/env bash
# Hook SessionEnd : place le session_id dans le presse-papier (et le garde sur disque).
# Récupération manuelle : cat ~/.claude/last-session-id
set -uo pipefail

payload=$(cat)
id=$(printf '%s' "$payload" | jq -r '.session_id // empty')
[ -n "$id" ] || exit 0

printf '%s\n' "$id" > ~/.claude/last-session-id

if command -v wl-copy >/dev/null 2>&1 && [ -n "${WAYLAND_DISPLAY:-}" ]; then
  # setsid : wl-copy doit survivre à la fin du groupe de processus de la session
  setsid wl-copy -- "$id" </dev/null >/dev/null 2>&1 &
elif command -v xclip >/dev/null 2>&1; then
  setsid bash -c "printf '%s' '$id' | xclip -selection clipboard" </dev/null >/dev/null 2>&1 &
elif command -v xsel >/dev/null 2>&1; then
  setsid bash -c "printf '%s' '$id' | xsel --clipboard --input" </dev/null >/dev/null 2>&1 &
fi
exit 0
