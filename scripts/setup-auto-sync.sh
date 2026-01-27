#!/bin/bash
# -----------------------------------------------------
# SETUP AUTO-SYNC
# -----------------------------------------------------
# Installs a cron job to run sync-state.sh every 6 hours
# Idempotent - safe to run multiple times

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
SYNC_SCRIPT="$SCRIPT_DIR/sync-state.sh"

log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

# Cron entry - runs every 6 hours at :00 minutes
CRON_SCHEDULE="0 */6 * * *"
CRON_COMMAND="$SYNC_SCRIPT"
CRON_ENTRY="$CRON_SCHEDULE $CRON_COMMAND"
CRON_MARKER="# dotfiles-auto-sync"

# -----------------------------------------------------
# Check Dependencies
# -----------------------------------------------------
check_dependencies() {
    # Check if cron is available
    if ! command -v crontab &> /dev/null; then
        error "crontab command not found"
        echo "Install cronie: sudo pacman -S cronie"
        echo "Then enable it: sudo systemctl enable --now cronie"
        exit 1
    fi
    
    # Check if cronie service is running
    if systemctl is-active --quiet cronie 2>/dev/null; then
        success "cronie service is running"
    else
        warn "cronie service may not be running"
        echo "Enable it with: sudo systemctl enable --now cronie"
    fi
    
    # Check if sync script exists and is executable
    if [ ! -x "$SYNC_SCRIPT" ]; then
        error "Sync script not found or not executable: $SYNC_SCRIPT"
        exit 1
    fi
    success "Sync script found: $SYNC_SCRIPT"
}

# -----------------------------------------------------
# Install Cron Job
# -----------------------------------------------------
install_cron() {
    log "Installing cron job..."
    
    # Get current crontab (suppress error if empty)
    local current_crontab
    current_crontab=$(crontab -l 2>/dev/null || echo "")
    
    # Check if our cron job already exists
    if echo "$current_crontab" | grep -q "$CRON_MARKER"; then
        success "Cron job already installed"
        echo ""
        echo "Current cron entry:"
        echo "$current_crontab" | grep "$CRON_MARKER" -A1
        return 0
    fi
    
    # Add our cron job
    local new_crontab="$current_crontab
$CRON_MARKER
$CRON_ENTRY
"
    
    # Install new crontab
    echo "$new_crontab" | crontab -
    
    success "Cron job installed"
    echo ""
    echo "Added cron entry:"
    echo "  $CRON_ENTRY"
    echo ""
    echo "This will run sync-state.sh every 6 hours (at 00:00, 06:00, 12:00, 18:00)"
}

# -----------------------------------------------------
# Remove Cron Job
# -----------------------------------------------------
remove_cron() {
    log "Removing cron job..."
    
    # Get current crontab
    local current_crontab
    current_crontab=$(crontab -l 2>/dev/null || echo "")
    
    # Check if our cron job exists
    if ! echo "$current_crontab" | grep -q "$CRON_MARKER"; then
        warn "Cron job not found"
        return 0
    fi
    
    # Remove our cron job (marker line and the line after it)
    local new_crontab
    new_crontab=$(echo "$current_crontab" | grep -v "$CRON_MARKER" | grep -v "sync-state.sh")
    
    # Install new crontab (or remove if empty)
    if [ -z "$(echo "$new_crontab" | tr -d '[:space:]')" ]; then
        crontab -r 2>/dev/null || true
    else
        echo "$new_crontab" | crontab -
    fi
    
    success "Cron job removed"
}

# -----------------------------------------------------
# Show Status
# -----------------------------------------------------
show_status() {
    echo ""
    echo -e "${BLUE}Current crontab:${NC}"
    echo ""
    crontab -l 2>/dev/null || echo "(empty)"
    echo ""
    
    echo -e "${BLUE}Recent sync log:${NC}"
    echo ""
    if [ -f "$DOTFILES_DIR/logs/sync-state.log" ]; then
        tail -20 "$DOTFILES_DIR/logs/sync-state.log"
    else
        echo "(no log file yet)"
    fi
}

# -----------------------------------------------------
# Test Sync
# -----------------------------------------------------
test_sync() {
    log "Running sync script manually..."
    echo ""
    "$SYNC_SCRIPT"
}

# -----------------------------------------------------
# Usage
# -----------------------------------------------------
usage() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  install   Install the cron job (default)"
    echo "  remove    Remove the cron job"
    echo "  status    Show current status"
    echo "  test      Run sync manually"
    echo "  help      Show this help"
    echo ""
}

# -----------------------------------------------------
# Main
# -----------------------------------------------------
main() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  Setup Auto-Sync${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    local command="${1:-install}"
    
    case "$command" in
        install)
            check_dependencies
            install_cron
            echo ""
            echo "To enable auto-push to remote, set environment variable:"
            echo "  export DOTFILES_AUTO_PUSH=true"
            echo ""
            echo "To test the sync manually:"
            echo "  $SYNC_SCRIPT"
            ;;
        remove)
            remove_cron
            ;;
        status)
            show_status
            ;;
        test)
            test_sync
            ;;
        help|--help|-h)
            usage
            ;;
        *)
            error "Unknown command: $command"
            usage
            exit 1
            ;;
    esac
    
    echo ""
}

main "$@"
