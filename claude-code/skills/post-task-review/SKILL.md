---
name: post-task-review
description: After completing significant work (design, planning, bug fix, feature, investigation), review findings, capture unrecorded user intent, update lessons learned, and propose CLAUDE.md updates. Should be performed as part of task completion, not only when explicitly invoked.
---

# Post-Task Review

After completing significant work, capture knowledge from the session, review findings, and update project memory.

## When to Use

- After completing a bug fix, feature, or investigation
- When the user says work is done, asks to wrap up, or asks for a review
- After touching multiple files and gaining codebase insight

Do NOT use for trivial changes (typo fixes, single-line edits).

## Workflow

```
Task completed
    │
    ├─ 1. Capture Unrecorded User Intent
    │     └─ Capture user intent/rationale not yet persisted to project memory
    │
    ├─ 2. Review Findings
    │     └─ Present prioritized summary to user
    │
    ├─ 3. Create GitHub Issues (with user approval)
    │
    ├─ 4. Update Lessons Learned
    │     └─ Document patterns from corrections encountered during task
    │
    └─ 5. Propose CLAUDE.md / Skills Updates
          └─ Apply with user approval
```

### 1. Capture Unrecorded User Intent

Review the session for user knowledge that was expressed or implied but NOT yet persisted to project memory (CLAUDE.md, design docs, etc.).

**What to look for:**

- **Context injections**: The user provided background, motivation, or "why" that guided the work — is it captured in project docs?
- **Unexplained choices**: The user selected an option without stating the reasoning. Ask: "You chose X over Y — what was your reasoning?" and persist the answer.
- **Corrected assumptions**: The user corrected the agent's understanding — is the corrected understanding now reflected in project memory?
- **Implicit goals**: Objectives or constraints the user "just knows" but don't appear anywhere in docs or CLAUDE.md.

Collect these items — they feed into Step 5.

### 2. Review Findings

Identify issues discovered during work. Categories to check:

- **Spec-code parity gaps**: Mismatches between documentation/specs and actual code behavior
- **Duplicated logic**: Same business logic in multiple files
- **Inconsistent patterns**: Different approaches to the same problem across files
- **Missing tests**: Untested critical paths found during investigation
- **Tight coupling**: Components that should be separated
- **Dependency concerns**: Version mismatches, deprecated APIs

Present a prioritized summary to the user. Ask which items to log.

### 3. Log Issues

Each approved item must include:

- **Summary**: What the problem is, with specific file paths and line numbers
- **Proposed Solution**: Concrete direction, not vague suggestions
- **Priority**: Why it matters (data integrity, performance, maintainability)

**Where to log**: Ask the user how they want to track the issues. Suggest options based on context:

- **GitHub Issues**: `gh issue create` with appropriate labels (if the project has a GitHub remote)
- **Local file**: A markdown file or `docs/issues/` directory in the project
- **Conversation output**: Formatted markdown for the user to copy elsewhere

### 4. Update Lessons Learned

Check if corrections occurred during the task. If so, capture them using this format:

- **Mistake**: What went wrong (be specific)
- **Pattern**: The underlying cause or anti-pattern
- **Rule**: Concrete, actionable rule to prevent recurrence
- **Applied**: Where this rule applies (specific files, patterns, situations)

> "Be more careful" is not a rule. Rules must be specific and testable.

Where to persist: project CLAUDE.md, auto memory, or a dedicated lessons file if the project has one.

### 5. Propose CLAUDE.md / Skills Updates

Check if the work revealed knowledge that would reduce future investigation time:

- **Architecture notes**: How subsystems connect, data flow, key design decisions
- **Build/test commands**: New test targets, lint configurations
- **Duplication risks**: List of files that must be updated together
- **Tech stack changes**: New dependencies, version requirements

Think about the best place for each item and propose to the user:

- **Project CLAUDE.md** — project-specific knowledge and best practices for all agents working on this repo
- **New skill** — recurring patterns or named workflows that require multiple steps to execute (look at session logs for repeated action sequences)
- **User's Global CLAUDE.md** — if the insight is a core belief or fundamental principle not tied to a specific project
- **Auto memory** — session-spanning context that doesn't belong in CLAUDE.md

Propose specific additions to the user before editing.

## What NOT to Do

- Do not create issues without user approval
- Do not add speculative or hypothetical issues
- Do not update CLAUDE.md with information already documented
- Do not add generic best practices — only project-specific knowledge discovered during the task
