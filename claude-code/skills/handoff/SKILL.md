---
name: handoff
description: Use after completing a plan, roadmap, design, or reaching a decision through discussion — when the next step is implementation in a fresh session. Also use when the user explicitly says "handoff", "hand off", "ハンドオフ", "引き継ぎ", "新しいセッションで", or asks to prepare context for a new session. If a planning or brainstorming session has concluded and implementation remains, proactively ask the user if they want a handoff.
---

# Handoff

Generate a handoff note and ready-to-paste prompt so work can resume immediately in a new session.

## Arguments

Optional: task description or ticket key (e.g., `/handoff API-307 implement auth debug tools`)

## Workflow

1. **Check for existing handoff notes** in the current project's memory directory:
   - Use Glob to search for `*-handoff.md` in the project memory directory
   - If a relevant note exists, plan to update it rather than creating a new one

2. **Gather context** from the current session:
   - What was discussed / decided (key design decisions)
   - What was completed vs what remains
   - Relevant tickets, PRs, branches, files
   - Repository path and key file locations
   - Any blockers or open questions

3. **Write handoff note** to the current project's memory directory:
   - Use the auto memory directory that is already configured for the project (the same directory where MEMORY.md lives)
   - File name: `{topic}-handoff.md`
   - Keep it factual and scannable (headers, bullets, tables)
   - Include links to tickets, docs, PRs

4. **Generate prompt** for the new session:
   - Output a fenced code block containing a self-contained prompt
   - The prompt should include:
     - Task objective (what to do)
     - Pointer to handoff note (`read {path} before starting`)
     - Key constraints or decisions already made
     - Suggested first steps
   - The prompt should NOT include:
     - Full design details (those are in the handoff note)
     - Lengthy context that bloats the initial prompt

5. **Update MEMORY.md** index if the handoff note is new

## Output Format

```
Handoff note saved: {path}

## Prompt for new session

\`\`\`
{generated prompt}
\`\`\`
```

## Guidelines

- Prefer updating an existing handoff note over creating duplicates
- Keep the prompt under 30 lines — the handoff note carries the detail
- Write handoff notes and prompts in the same language the user has been using
- If the user provides a ticket key, include it prominently in both the note and prompt
- **State verification on resume**: The user may have made changes between sessions (manual edits, other tools, rebases, etc.). Both the handoff note and generated prompt MUST instruct the new session to verify the actual state before proceeding — e.g., `git status`, `git diff --stat`, check running processes. Never assume the handoff note perfectly reflects the current state.
