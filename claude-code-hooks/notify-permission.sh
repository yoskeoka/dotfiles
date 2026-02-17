#!/bin/bash
# Notify when Claude needs permission approval to continue.
# Security: validate input, quote all variables, use absolute paths.

set -euo pipefail

NOTIFIER="/opt/homebrew/bin/terminal-notifier"

if [[ ! -x "$NOTIFIER" ]]; then
  exit 0
fi

# Read JSON from stdin safely
INPUT="$(cat)"

# Sanitize: strip control characters and truncate
sanitize() {
  local value="$1"
  local max_len="${2:-200}"
  value="$(printf '%s' "$value" | tr -d '\000-\011\013-\037' | head -c "$max_len")"
  printf '%s' "$value"
}

MESSAGE="$(printf '%s' "$INPUT" | /usr/bin/jq -r '.message // "Permission required"' 2>/dev/null || echo "Permission required")"
MESSAGE="$(sanitize "$MESSAGE" 200)"

"$NOTIFIER" \
  -title "Claude Code" \
  -subtitle "Permission Required" \
  -message "$MESSAGE" \
  -sound "Purr" \
  -group "claude-code-permission" \
  >/dev/null 2>&1

exit 0
