# Claude Code: Finding Implementation Context from Past Sessions

This file describes how to search Claude Code session history when the current session
did not perform the implementation. Other AI agents may have different session formats.

## When to use

- You are creating a PR but the implementation was done in a different session
- You need to find what directives, constraints, or trade-off decisions were communicated

## Search script

Use the script at `~/.claude/skills/create-pr/search-session-history.py`.

### Search by branch name (most common)

```bash
python3 ~/.claude/skills/create-pr/search-session-history.py --branch <branch-name>
```

### Search by ticket ID

```bash
python3 ~/.claude/skills/create-pr/search-session-history.py --ticket API-98
```

### Search by keyword

```bash
python3 ~/.claude/skills/create-pr/search-session-history.py --keyword "performance" "cache"
```

### Combined search (narrower results)

```bash
python3 ~/.claude/skills/create-pr/search-session-history.py --branch feat/x --keyword "security"
```

### Search all projects (last resort)

```bash
python3 ~/.claude/skills/create-pr/search-session-history.py --all-projects --keyword "some-unique-term"
```

### Options

- `--project PATH` — Override auto-detected project root
- `--all-projects` — Search ALL project directories (ignores project auto-detection)
- `--max-results N` — Max messages to display per session (default: 30)

## What to look for in the results

Scan the USER messages for:
- Directives: "keep it simple", "prioritize X over Y", "don't touch Z"
- Scope: "include X", "leave Y for later", "out of scope"
- Trade-off decisions: "I'd rather have A than B"

Scan the AI messages for:
- Proposals that the user accepted or rejected
- "Should we X or Y?" questions where the user made a choice
- Warnings or concerns the AI raised that shaped the final approach

## How it works

- Sessions are stored as JSONL files in `~/.claude/projects/<normalized-project-path>/`
- Each line is a JSON object with `type` (user/assistant/progress/etc.), `gitBranch`, `cwd`, `timestamp`
- The script automatically searches the project directory, worktree directories, AND parent directories
- Path normalization: `/` and `.` in the project path become `-` in the directory name

## Known quirks

- **Worktree sessions record `gitBranch: "HEAD"`** instead of the real branch name. The script
  works around this by also searching message content for the branch name (plan files, commit
  messages, and user instructions usually contain it).
- **Sessions started from a parent directory** (e.g. `moneyforward/`) may contain work done
  in a subdirectory (e.g. `moneyforward/suzaku/`). The script automatically includes parent
  directory sessions in its search scope.

## Limitations

- Only searches Claude Code sessions (not other AI tools)
- Sessions may be pruned or missing if the user cleaned up `~/.claude/`
- If no matching session is found, skip the AI Implementation Context section rather than guessing
