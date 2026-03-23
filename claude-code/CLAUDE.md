# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## User Rules

- Always respond in the same language I used to ask the question
  - If I ask in Japanese, respond in Japanese
  - If I ask in English, respond in English
    - Especially this one, even you detect Japanese somewhere, respond in English if I ask in English
  - When I switch languages in the same chat, follow the new language
- For referenced data sources (Web Search results, API responses, STDOUT/STDERR messages):
  - Keep English and Japanese content in its original language
  - Translate other languages (Chinese, French, etc.) to Japanese
- Code comments and documentation should always be written in English
- When user query or context includes 'https://github.com/moneyforward/', don't use web access and use GitHub CLI(gh command)

## GitHub CLI Usage

- Avoid `gh api` — prefer dedicated subcommands (`gh pr`, `gh issue`, `gh search`, etc.)
- NEVER use `gh api` for write operations or GraphQL mutations
- When `gh api` fails on the first attempt, do NOT retry with a different `gh api` call — reconsider whether a dedicated subcommand can do the job
- **PR inline comments (review comments on diffs):** Use `~/dotfiles/claude-code/scripts/gh-pr-comments.sh` instead of constructing `gh api` calls manually. `gh pr view --comments` only shows conversation-level comments, not inline code review comments.
  - Usage: `~/dotfiles/claude-code/scripts/gh-pr-comments.sh [--no-bots] [reviewer] [owner/repo] [pr_number]`
  - Auto-detects repo and PR number from the current branch if omitted

## Git Usage

- Never force push (`--force` / `--force-with-lease`); prefer normal pushes only
- Never amend commits (`--amend`); create new commits instead
- Keep commit history as-is even if it looks messy; squash merges will handle cleanup when needed
- Prefer `merge` over `rebase` to avoid rewriting history
- Use `git revert` instead of `git reset` to undo changes, preserving history
- Never run destructive commands (`reset --hard`, `checkout .`, `clean -f`, `branch -D`) unless explicitly requested by the user
- **Override: If the user explicitly specifies a git command, follow that instruction even if it contradicts the rules above**

## Needle-in-a-Haystack Search Pattern

When searching through large volumes of external resources to find specific, small pieces of information (validation checks, key facts, evidence of past decisions, etc.), delegate the search to a subagent and return only a consolidated report with findings and evidence.

**When to apply:**
- Web search for past error solutions, known issues, or specific technical facts
- GitHub issues/PRs search (`gh` CLI) for past decisions, related changes, or specific outcomes
- Backlog, Slack, Confluence, or other knowledge bases with accumulated historical data
- Any task where the ratio of "data to scan" vs "information to extract" is high

**How to execute:**
- Use the Task tool with `subagent_type="general-purpose"` for the search agent
- Choose the model based on search complexity:
  - `model="haiku"` — Simple keyword lookups, straightforward fact checks, single-source searches
  - `model="sonnet"` — Multi-source cross-referencing, nuanced interpretation, complex filtering across many results
  - `model="opus"` — Only when deep reasoning about ambiguous or contradictory findings is required
- The prompt to the subagent must clearly specify:
  1. What to search for (specific keywords, error messages, decision context, etc.)
  2. Where to search (which tools/sources to use)
  3. What to return: a concise report containing either the found result(s) with supporting evidence (URLs, quotes, dates) or an explicit "not found" conclusion with a summary of what was searched
- Launch multiple search subagents in parallel when searching independent sources simultaneously
- Do NOT dump raw search results into the main conversation — always summarize findings before presenting to the user

**Report format the subagent should return:**
- **Found / Not Found** status
- **Evidence**: Direct quotes, URLs, issue/PR numbers, dates
- **Search scope**: What sources were checked and what queries were used
- **Confidence**: How confident the finding is (exact match, partial match, inferred)

## Post-Task Review

- After completing significant tasks (bug fixes, feature implementations, investigations), invoke the `post-task-review` skill to review for architectural debt, propose GitHub issues, and suggest CLAUDE.md updates
