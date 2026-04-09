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
    exit 2
  fi
done

# gh api: block write operations and sensitive endpoints
if echo "$COMMAND" | grep -qE "^gh api\b|;\s*gh api\b|\|\s*gh api\b"; then
  # Block explicit write methods: -X POST/PUT/PATCH/DELETE, --method POST/PUT/PATCH/DELETE
  if echo "$COMMAND" | grep -qEi -- "-X\s*(POST|PUT|PATCH|DELETE)\b|--method\s*(POST|PUT|PATCH|DELETE)\b"; then
    cat >&2 <<'EOF'
BLOCKED: gh api with write method is not allowed.
Use dedicated gh subcommands instead:
  - Create PR comment:    gh pr comment <number> --body "..."
  - Create issue comment:  gh issue comment <number> --body "..."
  - Edit PR:              gh pr edit <number> ...
  - Edit issue:           gh issue edit <number> ...
  - Merge PR:             gh pr merge <number>
  - Close issue:          gh issue close <number>
EOF
    exit 2
  fi
  # Block GraphQL mutations
  if echo "$COMMAND" | grep -qE "mutation\s*(\{|\()"; then
    cat >&2 <<'EOF'
BLOCKED: gh api graphql mutation is not allowed.
Use dedicated gh subcommands instead:
  - PR comments:    gh pr view <number> --comments / gh pr comment <number> --body "..."
  - Issue comments:  gh issue view <number> --comments / gh issue comment <number> --body "..."
  - CI status:       gh pr checks <number>
  - Search:          gh search issues/prs/repos ...
EOF
    exit 2
  fi
  # Block -f/--field with input (often used for POST body, implies write)
  if echo "$COMMAND" | grep -qE -- "(-f|--field)\s+" && ! echo "$COMMAND" | grep -qE "graphql|/graphql"; then
    cat >&2 <<'EOF'
BLOCKED: gh api with -f/--field (likely write operation) is not allowed.
Use dedicated gh subcommands instead:
  - Create PR comment:    gh pr comment <number> --body "..."
  - Create issue comment:  gh issue comment <number> --body "..."
  - Edit PR:              gh pr edit <number> ...
  - Edit issue:           gh issue edit <number> ...
EOF
    exit 2
  fi
fi

exit 0
