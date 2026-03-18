#!/bin/bash

COMMAND=$(jq -r '.tool_input.command // .command // empty' < /dev/stdin)

DANGEROUS_PATTERNS=(
  "rm -rf"
  "curl.*|.*bash"
  "wget.*|.*bash"
  "chmod 777"
  "mkfs"
  "dd if="
  "> /dev/sd"
)

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qE "$pattern"; then
    echo "BLOCKED: Dangerous command pattern detected: $pattern" >&2
    exit 2  # Claude Code: exit 2 to indicate blocked command
  fi
done

exit 0
