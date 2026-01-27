#!/bin/bash
# -----------------------------------------------------
# SYNC STATE
# -----------------------------------------------------
# Captures state and auto-commits changes
# Designed to be run by cron every 6 hours
#
# Environment variables:
#   DOTFILES_AUTO_PUSH - Set to "true" to auto-push after commit
#   DOTFILES_DIR - Override dotfiles directory (default: ~/.dotfiles)

# Don't exit on error - we want to log errors and continue
set +e

# Get dotfiles directory
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
LOGS_DIR="$DOTFILES_DIR/logs"
LOG_FILE="$LOGS_DIR/sync-state.log"
SCRIPTS_DIR="$DOTFILES_DIR/scripts"

# Ensure logs directory exists
mkdir -p "$LOGS_DIR"

# Logging function with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log_stdout() {
    local msg
    msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$msg"
    echo "$msg" >> "$LOG_FILE"
}

# -----------------------------------------------------
# Main sync function
# -----------------------------------------------------
sync_state() {
    log_stdout "Starting state sync..."
    
    # Change to dotfiles directory
    if ! cd "$DOTFILES_DIR"; then
        log_stdout "ERROR: Could not change to $DOTFILES_DIR"
        return 1
    fi
    
    # Check if git repo
    if ! git rev-parse --git-dir &>/dev/null; then
        log_stdout "ERROR: $DOTFILES_DIR is not a git repository"
        return 1
    fi
    
    # Run capture-state.sh
    log_stdout "Capturing system state..."
    if ! "$SCRIPTS_DIR/capture-state.sh" >> "$LOG_FILE" 2>&1; then
        log_stdout "WARNING: capture-state.sh had errors (continuing anyway)"
    fi
    
    # Check for changes in state directory
    log_stdout "Checking for changes..."
    
    # Stage state files
    git add state/ 2>/dev/null || true
    
    # Check if there are staged changes
    if git diff --cached --quiet state/; then
        log_stdout "No changes detected in state files"
        return 0
    fi
    
    # Generate commit message with hostname
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local machine
    if command -v hostname &>/dev/null; then
        machine=$(hostname)
    elif [ -f /etc/hostname ]; then
        machine=$(cat /etc/hostname | tr -d '[:space:]')
    else
        machine="unknown"
    fi
    local commit_msg="Auto-sync [$machine]: Update system state ($timestamp)"
    
    # Count changes
    local changes
    changes=$(git diff --cached --stat state/ | tail -1)
    log_stdout "Changes detected: $changes"
    
    # Commit changes
    log_stdout "Committing changes..."
    if git commit -m "$commit_msg" >> "$LOG_FILE" 2>&1; then
        log_stdout "Committed: $commit_msg"
    else
        log_stdout "ERROR: Failed to commit changes"
        return 1
    fi
    
    # Auto-push if enabled
    if [ "${DOTFILES_AUTO_PUSH:-false}" = "true" ]; then
        log_stdout "Auto-push enabled, pushing to remote..."
        if git push >> "$LOG_FILE" 2>&1; then
            log_stdout "Pushed to remote successfully"
        else
            log_stdout "WARNING: Failed to push to remote (will retry next sync)"
        fi
    else
        log_stdout "Auto-push disabled (set DOTFILES_AUTO_PUSH=true to enable)"
    fi
    
    log_stdout "State sync complete"
    return 0
}

# -----------------------------------------------------
# Main
# -----------------------------------------------------
main() {
    log "═══════════════════════════════════════════════════════════"
    log "Sync started"
    
    sync_state
    local result=$?
    
    log "Sync finished with exit code: $result"
    log "═══════════════════════════════════════════════════════════"
    
    return $result
}

main "$@"
