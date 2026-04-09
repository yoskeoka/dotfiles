#!/usr/bin/env python3
"""Search Claude Code session history for implementation context.

Searches JSONL session files for user messages and assistant responses
matching a branch name, ticket ID, or keyword.

Usage:
    python3 search-session-history.py --branch feat/my-feature
    python3 search-session-history.py --keyword "performance" "cache"
    python3 search-session-history.py --ticket API-98
    python3 search-session-history.py --branch feat/x --keyword "security"
    python3 search-session-history.py --all-projects --keyword "API-98"

Options:
    --branch NAME     Match sessions by git branch name OR message content (partial match)
    --ticket ID       Search message content for this ticket/issue ID
    --keyword WORD    Search message content for keywords (multiple allowed)
    --project PATH    Absolute path to the project root (auto-detected from cwd)
    --all-projects    Search ALL project directories (use when session may be in a parent dir)
    --max-results N   Max number of matching message pairs to show (default: 30)
"""

import argparse
import json
import glob
import os
import re
import sys
from pathlib import Path


def find_project_dirs(project_path: str, include_parents: bool = False) -> list[str]:
    """Find all Claude session dirs for a project, including worktrees and parent dirs."""
    claude_projects = os.path.expanduser("~/.claude/projects")
    if not os.path.isdir(claude_projects):
        return []

    # Normalize project path to the Claude directory name format
    # Claude replaces both / and . with - in directory names
    # e.g., /Users/foo.bar/src/github.com/org/repo -> -Users-foo-bar-src-github-com-org-repo
    normalized = project_path.replace("/", "-").replace(".", "-")
    if not normalized.startswith("-"):
        normalized = "-" + normalized

    matches = []
    for entry in os.listdir(claude_projects):
        entry_path = os.path.join(claude_projects, entry)
        if not os.path.isdir(entry_path):
            continue
        # Exact match or worktree subdirectory (project path is a prefix)
        if entry == normalized or entry.startswith(normalized + "-"):
            matches.append(entry_path)

    # Also search parent directory sessions — sessions started from a parent dir
    # (e.g., moneyforward/) may contain work done in a subdirectory (e.g., moneyforward/suzaku/)
    if include_parents:
        path_parts = normalized.split("-")
        # Try progressively shorter prefixes (parent dirs)
        for i in range(len(path_parts) - 1, 2, -1):
            parent_normalized = "-".join(path_parts[:i])
            for entry in os.listdir(claude_projects):
                entry_path = os.path.join(claude_projects, entry)
                if not os.path.isdir(entry_path):
                    continue
                if entry == parent_normalized and entry_path not in matches:
                    matches.append(entry_path)

    return sorted(matches)


def find_all_project_dirs() -> list[str]:
    """Find ALL Claude session directories."""
    claude_projects = os.path.expanduser("~/.claude/projects")
    if not os.path.isdir(claude_projects):
        return []

    matches = []
    for entry in os.listdir(claude_projects):
        entry_path = os.path.join(claude_projects, entry)
        if os.path.isdir(entry_path):
            matches.append(entry_path)
    return sorted(matches)


def extract_text(content) -> str:
    """Extract plain text from message content (string or content blocks)."""
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        parts = []
        for item in content:
            if isinstance(item, dict) and item.get("type") == "text":
                parts.append(item["text"])
        return "\n".join(parts)
    return ""


def load_session(filepath: str) -> dict:
    """Load a session JSONL file and return structured data."""
    messages = []
    branches = set()
    cwd = None
    session_id = None

    with open(filepath, "r", errors="replace") as f:
        for line in f:
            try:
                obj = json.loads(line)
            except json.JSONDecodeError:
                continue

            if not session_id and obj.get("sessionId"):
                session_id = obj["sessionId"]
            if not cwd and obj.get("cwd"):
                cwd = obj["cwd"]
            if obj.get("gitBranch"):
                branches.add(obj["gitBranch"])

            msg_type = obj.get("type")
            if msg_type in ("user", "assistant"):
                text = extract_text(obj.get("message", {}).get("content", ""))
                if text.strip():
                    messages.append(
                        {
                            "role": msg_type,
                            "text": text.strip(),
                            "timestamp": obj.get("timestamp", ""),
                        }
                    )

    return {
        "file": filepath,
        "session_id": session_id,
        "cwd": cwd,
        "branches": branches,
        "messages": messages,
    }


def match_session(session: dict, branch: str | None, ticket: str | None, keywords: list[str]) -> bool:
    """Check if a session matches the search criteria."""
    all_text = " ".join(m["text"] for m in session["messages"]).lower()

    # Branch filter: check gitBranch field first, then fall back to message content.
    # Worktree sessions often record "HEAD" instead of the real branch name,
    # but the branch name usually appears in messages (plan files, commit msgs, etc.)
    if branch:
        branch_lower = branch.lower()
        branch_in_field = any(branch_lower in b.lower() for b in session["branches"])
        branch_in_content = branch_lower in all_text
        if not branch_in_field and not branch_in_content:
            return False

    # If only branch was specified (no ticket/keyword), accept branch match
    if branch and not ticket and not keywords:
        return True

    # Ticket/keyword: messages must contain all search terms
    search_terms = []
    if ticket:
        search_terms.append(ticket.lower())
    search_terms.extend(k.lower() for k in keywords)

    if not search_terms:
        return True  # no content filter

    return all(term in all_text for term in search_terms)


def find_relevant_messages(
    messages: list[dict],
    ticket: str | None,
    keywords: list[str],
    max_results: int,
) -> list[dict]:
    """Find messages that contain the search terms, with surrounding context."""
    search_terms = []
    if ticket:
        search_terms.append(ticket.lower())
    search_terms.extend(k.lower() for k in keywords)

    if not search_terms:
        # No content filter: return all user messages and adjacent assistant responses
        results = []
        for msg in messages:
            results.append(msg)
            if len(results) >= max_results:
                break
        return results

    # Find indices of messages containing any search term
    hit_indices = set()
    for i, msg in enumerate(messages):
        text_lower = msg["text"].lower()
        if any(term in text_lower for term in search_terms):
            hit_indices.add(i)
            # Include 1 message before and after for context
            if i > 0:
                hit_indices.add(i - 1)
            if i < len(messages) - 1:
                hit_indices.add(i + 1)

    results = []
    for i in sorted(hit_indices):
        results.append(messages[i])
        if len(results) >= max_results:
            break
    return results


def highlight(text: str, terms: list[str], max_len: int = 500) -> str:
    """Truncate text and mark search term positions."""
    if len(text) <= max_len:
        return text

    # Find first occurrence of any term to center the excerpt
    lower = text.lower()
    first_pos = len(text)
    for term in terms:
        pos = lower.find(term.lower())
        if pos != -1 and pos < first_pos:
            first_pos = pos

    start = max(0, first_pos - max_len // 4)
    end = start + max_len
    excerpt = text[start:end]
    prefix = "..." if start > 0 else ""
    suffix = "..." if end < len(text) else ""
    return f"{prefix}{excerpt}{suffix}"


def detect_project_path() -> str:
    """Detect project path from cwd by finding the git root."""
    cwd = os.getcwd()
    path = cwd
    while path != "/":
        if os.path.isdir(os.path.join(path, ".git")):
            return path
        path = os.path.dirname(path)
    return cwd


def main():
    parser = argparse.ArgumentParser(
        description="Search Claude Code session history for implementation context."
    )
    parser.add_argument("--branch", help="Filter sessions by git branch name (partial match)")
    parser.add_argument("--ticket", help="Search for ticket/issue ID in message content")
    parser.add_argument("--keyword", nargs="+", default=[], help="Search for keywords in message content")
    parser.add_argument("--project", help="Project root path (default: auto-detect from cwd)")
    parser.add_argument("--all-projects", action="store_true", help="Search ALL project directories (use when session may be in a parent/sibling dir)")
    parser.add_argument("--max-results", type=int, default=30, help="Max matching messages to show (default: 30)")

    args = parser.parse_args()

    if not args.branch and not args.ticket and not args.keyword:
        parser.error("At least one of --branch, --ticket, or --keyword is required")

    project_path = args.project or detect_project_path()

    if args.all_projects:
        project_dirs = find_all_project_dirs()
    else:
        # Always include parent dirs — sessions started from a parent directory
        # (e.g. moneyforward/) often contain work done in subdirectories (e.g. suzaku/).
        # Worktree sessions also land in parent dirs with gitBranch="HEAD".
        project_dirs = find_project_dirs(project_path, include_parents=True)

    if not project_dirs:
        print(f"No session directories found for project: {project_path}", file=sys.stderr)
        print("Tip: Try --all-projects to search all session directories.", file=sys.stderr)
        sys.exit(1)

    print(f"Searching {len(project_dirs)} project dir(s)...", file=sys.stderr)

    # Collect all session files
    session_files = []
    for d in project_dirs:
        session_files.extend(glob.glob(os.path.join(d, "*.jsonl")))

    # Sort by modification time (newest first)
    session_files.sort(key=lambda f: os.path.getmtime(f), reverse=True)

    print(f"Found {len(session_files)} session(s) to scan.", file=sys.stderr)

    search_terms = []
    if args.ticket:
        search_terms.append(args.ticket)
    search_terms.extend(args.keyword)

    found_any = False
    for sf in session_files:
        session = load_session(sf)

        if not match_session(session, args.branch, args.ticket, args.keyword):
            continue

        found_any = True
        branches_str = ", ".join(sorted(session["branches"])) or "(unknown)"
        print(f"\n{'='*72}")
        print(f"Session: {session['session_id']}")
        print(f"File:    {session['file']}")
        print(f"Branch:  {branches_str}")
        print(f"CWD:     {session['cwd']}")
        print(f"{'='*72}")

        relevant = find_relevant_messages(
            session["messages"], args.ticket, args.keyword, args.max_results
        )
        for msg in relevant:
            role_label = "USER" if msg["role"] == "user" else "AI"
            ts = msg["timestamp"][:19] if msg["timestamp"] else ""
            text = highlight(msg["text"], search_terms)
            print(f"\n[{role_label}] {ts}")
            print(text)

    if not found_any:
        print("\nNo matching sessions found.", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
