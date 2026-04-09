#!/bin/bash
# Fetch PR inline/review comments (code review comments on diffs).
# gh pr view --comments does NOT show inline comments, so this uses gh api.
#
# Usage:
#   gh-pr-comments.sh [--no-bots] [reviewer] [owner/repo] [pr_number]
#
# Arguments:
#   --no-bots    Optional flag to exclude bot comments (e.g., Copilot)
#   reviewer     Optional GitHub username to filter comments by
#   owner/repo   Optional repository in owner/repo format (auto-detected if omitted)
#   pr_number    Optional PR number (auto-detected from current branch if omitted)
#
# Examples:
#   gh-pr-comments.sh
#   gh-pr-comments.sh --no-bots
#   gh-pr-comments.sh copilot
#   gh-pr-comments.sh --no-bots johndoe owner/repo 123
#
# Reference: https://github.com/cli/cli/issues/5788

set -euo pipefail

no_bots=false
reviewer=""
repo=""
pr_number=""

# Parse --no-bots flag
if [ "${1:-}" = "--no-bots" ]; then
    no_bots=true
    shift
fi

reviewer="${1:-}"
repo="${2:-}"
pr_number="${3:-}"

# Auto-detect repo if not provided
if [ -z "$repo" ]; then
    repo=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null) || true
    if [ -z "$repo" ]; then
        echo "Error: Could not detect repository. Please specify <owner/repo>" >&2
        exit 1
    fi
    echo "Detected repo: $repo" >&2
fi

# Auto-detect PR number if not provided
if [ -z "$pr_number" ]; then
    pr_number=$(gh pr view --json number -q .number 2>/dev/null) || true
    if [ -z "$pr_number" ]; then
        echo "Error: Could not detect PR number. Please specify PR number or checkout a branch with an associated PR" >&2
        exit 1
    fi
    echo "Detected PR #$pr_number" >&2
fi

# Build jq filter based on flags
if [ "$no_bots" = true ]; then
    if [ -n "$reviewer" ]; then
        jq_filter='[ .[] | select(.user.type == "User" and .user.login == $user) | { user: .user.login, diff_hunk, line, start_line, body } ]'
    else
        jq_filter='[ .[] | select(.user.type == "User") | { user: .user.login, diff_hunk, line, start_line, body } ]'
    fi
else
    if [ -n "$reviewer" ]; then
        jq_filter='[ .[] | select(.user.login == $user) | { user: .user.login, diff_hunk, line, start_line, body } ]'
    else
        jq_filter='[ .[] | { user: .user.login, diff_hunk, line, start_line, body } ]'
    fi
fi

# Execute API call with appropriate filter
if [ -n "$reviewer" ]; then
    gh api "repos/$repo/pulls/$pr_number/comments" | \
        jq --arg user "$reviewer" "$jq_filter"
else
    gh api "repos/$repo/pulls/$pr_number/comments" | \
        jq "$jq_filter"
fi
