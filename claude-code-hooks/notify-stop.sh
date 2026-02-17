#!/bin/bash
# Notify when Claude finishes responding and is waiting for user input.
# Security: validate input, quote all variables, use absolute paths.

set -euo pipefail

NOTIFIER="/opt/homebrew/bin/terminal-notifier"

if [[ ! -x "$NOTIFIER" ]]; then
  exit 0
fi

# Read JSON from stdin safely
INPUT="$(cat)"

# Sanitize: extract and truncate to prevent injection via overly long strings
sanitize() {
  local value="$1"
  local max_len="${2:-200}"
  # Strip control characters except newline, truncate
  value="$(printf '%s' "$value" | tr -d '\000-\011\013-\037' | head -c "$max_len")"
  printf '%s' "$value"
}

STOP_REASON="$(printf '%s' "$INPUT" | /usr/bin/jq -r '.stop_reason // "completed"' 2>/dev/null || echo "completed")"
STOP_REASON="$(sanitize "$STOP_REASON" 100)"

"$NOTIFIER" \
  -title "Claude Code" \
  -subtitle "Response Complete" \
  -message "Claude is waiting for you to check the response. (${STOP_REASON})" \
  -sound "Funk" \
  -group "claude-code-stop" \
  >/dev/null 2>&1

exit 0
