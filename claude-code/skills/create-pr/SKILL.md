---
name: create-pr
description: Use when the user asks to create a pull request, push and create PR, or says "PR" after completing implementation work
---

# Create Pull Request

## Overview

Push branch and create a PR with the repo's PR template. Focus on design decisions over code details. Include test/verification commands.

## Workflow

1. **Push branch** with `-u` flag
2. **Find PR template** (`.github/PULL_REQUEST_TEMPLATE.md` or similar)
3. **Create PR** using `gh pr create` with the template structure

## PR Body Structure

Follow the repo's PR template. Within that structure:

### AI Implementation Context (when applicable)

When the implementation was done with AI assistance, include the requirements and constraints that were communicated to the AI. This helps reviewers understand the intent behind the code.

**How to find the context:**
1. If the current session performed the implementation, use the conversation history directly
2. If this is a different session, search for the implementation session:
   - Check for exec-plan files or plan-mode artifacts in the repo/worktree
   - If a plan-mode file was used, find the session where the plan was created to recover the original requirements
   - **Claude Code**: Use the session search script. See `~/.claude/skills/create-pr/claude-code-session-search.md` for details.
     ```bash
     python3 ~/.claude/skills/create-pr/search-session-history.py --branch <current-branch>
     ```
   - If no matching session is found, skip this section rather than guessing
3. If the implementation was driven by a ticket (JIRA, GitHub Issues, exec-plan file, etc.), do NOT repeat the ticket content — just reference it. Focus on what was communicated beyond the ticket.

**What to include:**
- **Implementation directives**: What was emphasized when instructing the AI (e.g., "prioritize performance", "keep changes minimal", "ensure backward compatibility", "security-sensitive — validate all inputs")
- **Scope decisions**: What was explicitly included or excluded (e.g., "include X in this PR", "leave Y for a follow-up")
- **Requirements discovered during discussion**: Constraints or requirements that emerged from back-and-forth with the AI, not present in the original ticket
- **Judgment changes**: If trade-off priorities changed during implementation, show both the original and revised thinking (e.g., "Initially aimed for a generic solution, but switched to a targeted fix after discussing complexity trade-offs")

**What NOT to include:**
- Ticket/issue content that reviewers can read themselves
- Mechanical AI instructions ("use Go", "follow clean architecture") that are obvious from the codebase
- Every minor clarification — focus on decisions that shaped the final code

### Design Decisions (detailed)

For each non-trivial design choice made during implementation:
- What was decided
- What alternatives existed
- Why this option was chosen (trade-offs, constraints)

This is the most important section. Reviewers need to understand the "why" behind architectural choices.

### Code Changes (short summary)

One paragraph summarizing what changed. Do not enumerate every file. Reviewers can read the diff.

### Testing / Verification

Include runnable commands (curl, test commands, etc.) that reviewers can copy-paste to verify the changes work. Group by what they verify.

## Example

```bash
gh pr create --title "feat: short description" --body "$(cat <<'EOF'
# JIRA Task

TICKET-123

# Changes

## Summary

One paragraph describing what changed and why.

## AI Implementation Context

**Directives**: Keep changes minimal — only touch the token endpoint path. Avoid refactoring surrounding code even if it looks improvable.

**Scope decisions**: Include client_secret stripping logic in this PR. Leave admin UI changes for a follow-up.

**Emerged during discussion**: Initially planned to check DB first for all requests, but after discussing performance impact, decided to only check DB when the secret is present — reduces unnecessary queries for public clients.

**Judgment change**: Originally considered a generic "client type resolver" abstraction, but opted for a simple inline check after discussing that only one call site needs this logic today. YAGNI over extensibility.

## Design Decisions

### 1. Decision title

What was chosen, what alternatives existed, why this option.

### 2. Another decision

Same pattern.

## Testing

  bash
  curl -s https://example.com/endpoint | jq .

EOF
)"
```

## Common Mistakes

- Writing long file-by-file changelogs instead of a summary
- Skipping design decision rationale (the most valuable part for reviewers)
- Forgetting to include verification commands
- Not using the repo's PR template
- Copying ticket content into AI Implementation Context instead of focusing on directives and judgment calls
- Omitting requirements that emerged during AI discussion but weren't in the original ticket
- Not mentioning when trade-off priorities changed during implementation
