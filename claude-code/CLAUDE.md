# CLAUDE.md

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
- External outputs (GitHub PRs/issues/comments, Notion, Google Docs, Jira, Slack) should be written in English by default, regardless of conversation language, unless explicitly instructed otherwise. Disable caveman/genshijin mode for these outputs — write in normal, professional prose.
- When user query or context includes 'https://github.com/moneyforward/', don't use web access and use GitHub CLI(gh command)
- Always use terse response mode to reduce token consumption. For Japanese, use genshijin mode (`/genshijin` skill). For English, use caveman mode (`/caveman` skill). Standard level by default — strip filler, hedging, honorifics, and pleasantries. Keep all technical substance. User can override with `/genshijin off` or `/caveman off`.

## GitHub CLI Usage

- Avoid `gh api` — prefer dedicated subcommands (`gh pr`, `gh issue`, `gh search`, etc.)
- NEVER use `gh api` for write operations or GraphQL mutations
- When `gh api` fails on the first attempt, do NOT retry with a different `gh api` call — reconsider whether a dedicated subcommand can do the job
- **PR inline comments (review comments on diffs):** Use `~/dotfiles/claude-code/scripts/gh-pr-comments.sh` instead of constructing `gh api` calls manually. `gh pr view --comments` only shows conversation-level comments, not inline code review comments.
  - Usage: `~/dotfiles/claude-code/scripts/gh-pr-comments.sh [--no-bots] [reviewer] [owner/repo] [pr_number]`
  - Arguments are positional. To skip `reviewer`, pass an empty string: `--no-bots "" owner/repo 123`
  - Auto-detects repo and PR number from the current branch if omitted

## Git Usage

- Never force push (`--force` / `--force-with-lease`); prefer normal pushes only
- Never amend commits (`--amend`); create new commits instead
- Keep commit history as-is even if it looks messy; squash merges will handle cleanup when needed
- Prefer `merge` over `rebase` to avoid rewriting history
- Use `git revert` instead of `git reset` to undo changes, preserving history
- Never run destructive commands (`reset --hard`, `checkout .`, `clean -f`, `branch -D`) unless explicitly requested by the user
- **Override: If the user explicitly specifies a git command, follow that instruction even if it contradicts the rules above**

## Post-Task Review

- After completing significant tasks (bug fixes, feature implementations, investigations), invoke the `post-task-review` skill to review for architectural debt, propose GitHub issues, and suggest CLAUDE.md updates

@RTK.md
