#!/usr/bin/env bash
# claude-update-plugins.sh - Check and update Claude Code plugins
#
# Usage:
#   claude-update-plugins.sh [--check|--update|--force-update|--should-remind|--restore]
#
# Options:
#   --check          Check for available updates (default)
#   --update         Update plugins one by one with changelog review
#   --force-update   Update all plugins without prompting
#   --should-remind  Exit 0 if 7+ days since last check (for hooks)
#   --restore        Restore plugins from the latest backup

set -euo pipefail

MODE="${1:---check}"
SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
TIMESTAMP_FILE="$HOME/.claude/debug/.last-plugin-update-check"
INSTALLED_PLUGINS_JSON="$HOME/.claude/plugins/installed_plugins.json"
KNOWN_MARKETPLACES_JSON="$HOME/.claude/plugins/known_marketplaces.json"
MARKETPLACES_DIR="$HOME/.claude/plugins/marketplaces"
BACKUP_DIR="$HOME/.claude/plugins/backups"
PLUGINS_CACHE_DIR="$HOME/.claude/plugins/cache"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}[info]${NC} $*"; }
log_ok()    { echo -e "${GREEN}[ok]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[update]${NC} $*"; }
log_error() { echo -e "${RED}[error]${NC} $*"; }

# Track plugins that failed to reinstall after removal
UPDATE_FAILURES=()

# Create a timestamped backup of installed_plugins.json and plugin cache
create_backup() {
  local timestamp
  timestamp=$(date +%Y%m%d_%H%M%S)
  local backup_path="$BACKUP_DIR/$timestamp"
  mkdir -p "$backup_path"

  if [ -f "$INSTALLED_PLUGINS_JSON" ]; then
    cp "$INSTALLED_PLUGINS_JSON" "$backup_path/installed_plugins.json"
  fi
  if [ -d "$PLUGINS_CACHE_DIR" ]; then
    cp -R "$PLUGINS_CACHE_DIR" "$backup_path/cache"
  fi

  # Keep only the 3 most recent backups
  local count
  count=$(find "$BACKUP_DIR" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
  if [ "$count" -gt 3 ]; then
    find "$BACKUP_DIR" -mindepth 1 -maxdepth 1 -type d | sort | head -n "$((count - 3))" | while read -r old; do
      rm -rf "$old"
    done
  fi

  log_info "Backup created: ${DIM}$backup_path${NC}" >&2
  echo "$backup_path"
}

# Restore from the latest (or specified) backup
restore_backup() {
  local backup_path="${1:-}"

  if [ -z "$backup_path" ]; then
    # Find the latest backup
    backup_path=$(find "$BACKUP_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort | tail -1)
  fi

  if [ -z "$backup_path" ] || [ ! -d "$backup_path" ]; then
    log_error "No backup found to restore."
    return 1
  fi

  log_info "Restoring from: ${DIM}$backup_path${NC}"

  if [ -f "$backup_path/installed_plugins.json" ]; then
    cp "$backup_path/installed_plugins.json" "$INSTALLED_PLUGINS_JSON"
    log_ok "Restored installed_plugins.json"
  fi
  if [ -d "$backup_path/cache" ]; then
    rm -rf "$PLUGINS_CACHE_DIR"
    cp -R "$backup_path/cache" "$PLUGINS_CACHE_DIR"
    log_ok "Restored plugin cache"
  fi

  log_warn "Restart Claude Code to apply restored plugins."
}

# Fetch latest from all marketplace repos
fetch_marketplaces() {
  log_info "Fetching latest from marketplace repositories..."
  for mp_dir in "$MARKETPLACES_DIR"/*/; do
    local mp_name
    mp_name=$(basename "$mp_dir")
    if [ -d "$mp_dir/.git" ]; then
      printf "  %-30s " "$mp_name"
      local default_branch
      default_branch=$(get_default_branch "$mp_dir")
      if git -C "$mp_dir" fetch origin --quiet 2>/dev/null; then
        # Fast-forward local branch to match remote so claude plugin update sees latest
        if git -C "$mp_dir" merge-base --is-ancestor HEAD "origin/$default_branch" 2>/dev/null; then
          git -C "$mp_dir" merge --ff-only "origin/$default_branch" --quiet 2>/dev/null || true
        fi
        echo -e "${GREEN}fetched${NC}"
      else
        echo -e "${RED}failed${NC}"
      fi
    fi
  done
  echo ""
}

# Get the remote HEAD sha for a marketplace
get_remote_head() {
  local mp_dir="$1"
  git -C "$mp_dir" rev-parse origin/main 2>/dev/null || \
    git -C "$mp_dir" rev-parse origin/master 2>/dev/null || \
    echo ""
}

# Get the default branch name for a marketplace
get_default_branch() {
  local mp_dir="$1"
  if git -C "$mp_dir" rev-parse --verify origin/main &>/dev/null; then
    echo "main"
  else
    echo "master"
  fi
}

# Get changelog between two commits for a specific plugin directory
get_changelog() {
  local mp_dir="$1"
  local old_sha="$2"
  local new_sha="$3"
  local plugin_name="$4"

  if [ -z "$old_sha" ] || [ -z "$new_sha" ] || [ "$old_sha" = "$new_sha" ]; then
    return
  fi

  # Show commits that touch the plugin's directory
  local plugin_path="plugins/$plugin_name"
  if [ ! -d "$mp_dir/$plugin_path" ]; then
    plugin_path="$plugin_name"
  fi

  local log_output
  log_output=$(git -C "$mp_dir" log --oneline --no-merges \
    "${old_sha}..${new_sha}" -- "$plugin_path" 2>/dev/null || true)

  if [ -z "$log_output" ]; then
    # Only fall back to unfiltered log for single-plugin repos (e.g., superpowers-marketplace)
    local plugin_count
    plugin_count=$(find "$mp_dir/plugins" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
    if [ "$plugin_count" -le 1 ]; then
      log_output=$(git -C "$mp_dir" log --oneline --no-merges \
        "${old_sha}..${new_sha}" 2>/dev/null | head -15)
    fi
  fi

  echo "$log_output"
}

# Update plugin by removing and reinstalling (claude plugin update has a bug
# where it updates 'version' but not 'gitCommitSha', causing perpetual false positives)
run_plugin_update() {
  local plugin_id="$1"
  local scope="$2"
  local project_path="$3"

  local run_in_dir=""
  if [ -n "$project_path" ] && [ -d "$project_path" ]; then
    run_in_dir="$project_path"
  fi

  # Remove first, then reinstall
  local remove_ok=false install_ok=false
  if [ -n "$run_in_dir" ]; then
    if (cd "$run_in_dir" && claude plugin remove "$plugin_id" --scope "$scope" 2>&1) >/dev/null 2>&1; then
      remove_ok=true
    fi
    if (cd "$run_in_dir" && claude plugin install "$plugin_id" --scope "$scope" 2>&1) >/dev/null 2>&1; then
      install_ok=true
    fi
  else
    if claude plugin remove "$plugin_id" --scope "$scope" >/dev/null 2>&1; then
      remove_ok=true
    fi
    if claude plugin install "$plugin_id" --scope "$scope" >/dev/null 2>&1; then
      install_ok=true
    fi
  fi

  if $install_ok; then
    return 0
  else
    # Remove succeeded but install failed — plugin is in a broken state
    UPDATE_FAILURES+=("$plugin_id (scope: $scope)")
    return 1
  fi
}

# Build update info for all plugins
check_all_plugins() {
  local updates_available=0
  local updated_ok=0
  local update_failed=0
  local up_to_date=0
  local check_failed=0

  # Parse installed plugins
  local plugin_ids
  plugin_ids=$(python3 -c "
import json
with open('$INSTALLED_PLUGINS_JSON') as f:
    data = json.load(f)
for pid, installs in data.get('plugins', {}).items():
    for inst in installs:
        sha = inst.get('gitCommitSha', '')
        scope = inst.get('scope', 'user')
        version = inst.get('version', 'unknown')
        project_path = inst.get('projectPath', '')
        print(f'{pid}\t{sha}\t{scope}\t{version}\t{project_path}')
" 2>/dev/null)

  if [ -z "$plugin_ids" ]; then
    log_info "No plugins found."
    return 0
  fi

  # Create backup before any updates
  local backup_path=""
  if [ "$MODE" = "--update" ] || [ "$MODE" = "--force-update" ]; then
    backup_path=$(create_backup)
  fi

  echo -e "${BOLD}Plugin Update Status:${NC}"
  echo ""

  while IFS=$'\t' read -r plugin_id installed_sha scope version project_path; do
    local name="${plugin_id%%@*}"
    local marketplace="${plugin_id#*@}"
    local mp_dir="$MARKETPLACES_DIR/$marketplace"

    if [ ! -d "$mp_dir/.git" ]; then
      printf "  %-35s ${DIM}%-12s${NC} ${RED}marketplace not found${NC}\n" "$name" "($marketplace)"
      ((check_failed++))
      continue
    fi

    local remote_head
    remote_head=$(get_remote_head "$mp_dir")

    if [ -z "$remote_head" ]; then
      printf "  %-35s ${DIM}%-12s${NC} ${RED}could not get remote HEAD${NC}\n" "$name" "($marketplace)"
      ((check_failed++))
      continue
    fi

    if [ -z "$installed_sha" ]; then
      printf "  %-35s ${DIM}%-12s${NC} ${YELLOW}no sha recorded, update recommended${NC}\n" "$name" "($marketplace)"
      ((updates_available++))
      continue
    fi

    # Check if there are newer commits for this plugin
    local changelog
    changelog=$(get_changelog "$mp_dir" "$installed_sha" "$remote_head" "$name")

    if [ -n "$changelog" ]; then
      local commit_count
      commit_count=$(echo "$changelog" | wc -l | tr -d ' ')
      printf "  %-35s ${DIM}%-12s${NC} ${YELLOW}%s new commit(s)${NC} ${DIM}(installed: %s)${NC}\n" \
        "$name" "($marketplace)" "$commit_count" "${version}"

      if [ "$MODE" = "--check" ]; then
        echo "$changelog" | head -5 | while read -r line; do
          echo -e "    ${DIM}$line${NC}"
        done
        if [ "$commit_count" -gt 5 ]; then
          echo -e "    ${DIM}... and $((commit_count - 5)) more${NC}"
        fi
      fi

      ((updates_available++))

      # Interactive update
      if [ "$MODE" = "--update" ]; then
        echo ""
        echo -e "  ${CYAN}Changelog:${NC}"
        echo "$changelog" | while read -r line; do
          echo -e "    $line"
        done
        echo ""
        read -rp "  Update $name? [y/N/q] " answer </dev/tty
        case "$answer" in
          y|Y)
            printf "  Updating... "
            if run_plugin_update "$plugin_id" "$scope" "$project_path" >/dev/null; then
              echo -e "${GREEN}done${NC}"
              ((updated_ok++))
            else
              echo -e "${RED}failed${NC}"
              ((update_failed++))
            fi
            ;;
          q|Q)
            echo "  Aborted."
            return
            ;;
          *)
            echo "  Skipped."
            ;;
        esac
        echo ""
      fi

      # Force update
      if [ "$MODE" = "--force-update" ]; then
        printf "    Updating... "
        if run_plugin_update "$plugin_id" "$scope" "$project_path" >/dev/null; then
          echo -e "${GREEN}done${NC}"
          ((updated_ok++))
        else
          echo -e "${RED}failed${NC}"
          ((update_failed++))
        fi
      fi
    else
      printf "  %-35s ${DIM}%-12s${NC} ${GREEN}up to date${NC} ${DIM}(%s)${NC}\n" \
        "$name" "($marketplace)" "$version"
      ((up_to_date++))
    fi
  done <<< "$plugin_ids"

  echo ""
  if [ "$MODE" = "--check" ]; then
    echo -e "${BOLD}Summary:${NC} ${GREEN}${up_to_date} up to date${NC}, ${YELLOW}${updates_available} update(s) available${NC}, ${RED}${check_failed} failed${NC}"
    if [ "$updates_available" -gt 0 ]; then
      echo ""
      echo "  $SCRIPT_PATH --update        # interactive per-plugin updates"
      echo "  $SCRIPT_PATH --force-update  # update all at once"
    fi
  else
    echo -e "${BOLD}Summary:${NC} ${GREEN}$((up_to_date + updated_ok)) up to date${NC} (${updated_ok} updated), ${YELLOW}$((updates_available - updated_ok - update_failed)) update(s) remaining${NC}, ${RED}${update_failed} failed${NC}"
  fi

  if [ "${#UPDATE_FAILURES[@]}" -gt 0 ]; then
    echo ""
    log_error "The following plugins were removed but failed to reinstall:"
    for failure in "${UPDATE_FAILURES[@]}"; do
      echo -e "    ${RED}•${NC} $failure"
    done
    echo ""
    echo -e "  To restore all plugins to pre-update state:"
    echo -e "    ${BOLD}$SCRIPT_PATH --restore${NC}"
    echo ""
    echo -e "  Or manually reinstall a specific plugin:"
    echo -e "    ${DIM}claude plugin install <plugin@marketplace> --scope <scope>${NC}"
  elif [ "$updated_ok" -gt 0 ]; then
    log_warn "Restart Claude Code to apply updates."
  fi
}

# Check if it's been more than N days since last check
days_since_last_check() {
  if [ ! -f "$TIMESTAMP_FILE" ]; then
    echo "never"
    return
  fi
  local last_check
  last_check=$(cat "$TIMESTAMP_FILE")
  local now
  now=$(date +%s)
  local diff=$(( (now - last_check) / 86400 ))
  echo "$diff"
}

record_timestamp() {
  date +%s > "$TIMESTAMP_FILE"
}

case "$MODE" in
  --check)
    fetch_marketplaces
    check_all_plugins
    record_timestamp
    ;;
  --update)
    fetch_marketplaces
    check_all_plugins
    record_timestamp
    ;;
  --force-update)
    fetch_marketplaces
    check_all_plugins
    record_timestamp
    ;;
  --should-remind)
    days=$(days_since_last_check)
    if [ "$days" = "never" ] || [ "$days" -ge 7 ]; then
      cat <<ENDJSON
{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"PLUGIN_UPDATE_REMINDER: It has been ${days} days since the last Claude Code plugin update check. Suggest the user to run: ${SCRIPT_PATH} --check (to see available updates) or --update (to interactively update one by one with changelogs). Mention this briefly at an appropriate time, do not block the conversation."}}
ENDJSON
      exit 0
    else
      # No reminder needed, output nothing
      exit 0
    fi
    ;;
  --restore)
    restore_backup
    ;;
  *)
    echo "Usage: $0 [--check|--update|--force-update|--should-remind|--restore]"
    exit 1
    ;;
esac
