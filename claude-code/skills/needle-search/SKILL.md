---
name: needle-search
description: Use when searching external resources (GitHub issues/PRs, Slack, web, knowledge bases) to find information. Triggers on any investigation or search task - finding past decisions, error solutions, validation checks, or evidence. Also triggers on Japanese instructions like "探して", "検索して", "調べて", "検証して", "確認して", "過去のissueを見て". Delegates search to subagents to keep the main context clean.
---

# Needle-in-a-Haystack Search Pattern

Delegate large-volume searches to subagents and return only a consolidated report.

## When to Apply

- Web search for past error solutions, known issues, or specific technical facts
- GitHub issues/PRs search (`gh` CLI) for past decisions, related changes, or specific outcomes
- Backlog, Slack, Confluence, or other knowledge bases with accumulated historical data
- Any task where the ratio of "data to scan" vs "information to extract" is high

## Execution

1. **Use the Task tool** with `subagent_type="general-purpose"`
2. **Choose the model** based on complexity:
   - `model="haiku"` — Simple keyword lookups, straightforward fact checks, single-source searches
   - `model="sonnet"` — Multi-source cross-referencing, nuanced interpretation, complex filtering across many results
   - `model="opus"` — Only when deep reasoning about ambiguous or contradictory findings is required
3. **Subagent prompt must specify:**
   - What to search for (specific keywords, error messages, decision context, etc.)
   - Where to search (which tools/sources to use)
   - What to return (see report format below)
4. **Launch multiple subagents in parallel** when searching independent sources simultaneously
5. **Never dump raw results** into the main conversation — always summarize

## Report Format (for subagent prompt)

Instruct the subagent to return:

- **Found / Not Found** status
- **Evidence**: Direct quotes, URLs, issue/PR numbers, dates
- **Search scope**: What sources were checked and what queries were used
- **Confidence**: How confident the finding is (exact match, partial match, inferred)
