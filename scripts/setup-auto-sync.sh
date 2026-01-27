#!/bin/bash
# -----------------------------------------------------
# SETUP AUTO-SYNC
# -----------------------------------------------------
# Installs a systemd user timer to run sync-state.sh every 6 hours
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

# Systemd user unit directory
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
SERVICE_NAME="dotfiles-sync"

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

# -----------------------------------------------------
# Check Dependencies
# -----------------------------------------------------
check_dependencies() {
    # Check if sync script exists and is executable
    if [ ! -x "$SYNC_SCRIPT" ]; then
        error "Sync script not found or not executable: $SYNC_SCRIPT"
        exit 1
    fi
    success "Sync script found: $SYNC_SCRIPT"
}

# -----------------------------------------------------
# Create Service Unit
# -----------------------------------------------------
create_service() {
    local auto_push_line=""
    if [ "$ENABLE_AUTO_PUSH" = true ]; then
        auto_push_line="Environment=DOTFILES_AUTO_PUSH=true"
    else
        auto_push_line="# Environment=DOTFILES_AUTO_PUSH=true"
    fi
    
    cat > "$SYSTEMD_USER_DIR/$SERVICE_NAME.service" << EOF
[Unit]
Description=Dotfiles state sync
Documentation=https://github.com/your-username/dotfiles

[Service]
Type=oneshot
ExecStart=$SYNC_SCRIPT
WorkingDirectory=$DOTFILES_DIR

# Logging
StandardOutput=journal
StandardError=journal

# Environment
Environment=HOME=$HOME
Environment=PATH=/usr/local/bin:/usr/bin:/bin
$auto_push_line
EOF
    success "Created $SERVICE_NAME.service"
}

# -----------------------------------------------------
# Create Timer Unit
# -----------------------------------------------------
create_timer() {
    cat > "$SYSTEMD_USER_DIR/$SERVICE_NAME.timer" << EOF
[Unit]
Description=Run dotfiles sync every 6 hours

[Timer]
# Run every 6 hours
OnCalendar=*-*-* 00,06,12,18:00:00
# Run shortly after boot if a scheduled run was missed
Persistent=true
# Random delay up to 5 minutes to avoid exact timing
RandomizedDelaySec=300

[Install]
WantedBy=timers.target
EOF
    success "Created $SERVICE_NAME.timer"
}

# -----------------------------------------------------
# Install Timer
# -----------------------------------------------------
install_timer() {
    log "Installing systemd user timer..."
    
    # Create systemd user directory if needed
    mkdir -p "$SYSTEMD_USER_DIR"
    
    # Create units
    create_service
    create_timer
    
    # Reload systemd user daemon
    systemctl --user daemon-reload
    
    # Enable and start the timer
    systemctl --user enable "$SERVICE_NAME.timer"
    systemctl --user start "$SERVICE_NAME.timer"
    
    success "Timer installed and started"
    echo ""
    echo "The sync will run every 6 hours (00:00, 06:00, 12:00, 18:00)"
    echo "Plus a random delay of up to 5 minutes."
    echo ""
    echo "Next scheduled run:"
    systemctl --user list-timers "$SERVICE_NAME.timer" --no-pager
}

# -----------------------------------------------------
# Remove Timer
# -----------------------------------------------------
remove_timer() {
    log "Removing systemd user timer..."
    
    # Stop and disable
    systemctl --user stop "$SERVICE_NAME.timer" 2>/dev/null || true
    systemctl --user disable "$SERVICE_NAME.timer" 2>/dev/null || true
    
    # Remove unit files
    rm -f "$SYSTEMD_USER_DIR/$SERVICE_NAME.service"
    rm -f "$SYSTEMD_USER_DIR/$SERVICE_NAME.timer"
    
    # Reload
    systemctl --user daemon-reload
    
    success "Timer removed"
}

# -----------------------------------------------------
# Show Status
# -----------------------------------------------------
show_status() {
    echo ""
    echo -e "${BLUE}Timer Status:${NC}"
    echo ""
    systemctl --user status "$SERVICE_NAME.timer" --no-pager 2>/dev/null || echo "(timer not installed)"
    
    echo ""
    echo -e "${BLUE}Next Scheduled Runs:${NC}"
    echo ""
    systemctl --user list-timers "$SERVICE_NAME.timer" --no-pager 2>/dev/null || echo "(no timers)"
    
    echo ""
    echo -e "${BLUE}Recent Logs:${NC}"
    echo ""
    journalctl --user -u "$SERVICE_NAME.service" --no-pager -n 20 2>/dev/null || echo "(no logs yet)"
}

# -----------------------------------------------------
# Test Sync
# -----------------------------------------------------
test_sync() {
    log "Running sync service manually..."
    echo ""
    systemctl --user start "$SERVICE_NAME.service"
    echo ""
    echo "Check the logs with:"
    echo "  journalctl --user -u $SERVICE_NAME.service -f"
}

# -----------------------------------------------------
# View Logs
# -----------------------------------------------------
view_logs() {
    journalctl --user -u "$SERVICE_NAME.service" --no-pager -n 50
}

# -----------------------------------------------------
# Usage
# -----------------------------------------------------
usage() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  install   Install the systemd timer (default)"
    echo "  remove    Remove the systemd timer"
    echo "  status    Show current status"
    echo "  test      Run sync manually"
    echo "  logs      View recent logs"
    echo "  help      Show this help"
    echo ""
}

# -----------------------------------------------------
# Main
# -----------------------------------------------------
main() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  Setup Auto-Sync (systemd timer)${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    local command="${1:-install}"
    
    case "$command" in
        install)
            check_dependencies
            
            # Ask about auto-push
            echo ""
            echo "Auto-push will automatically push changes to your git remote"
            echo "after each sync. This requires SSH keys to be set up."
            echo ""
            read -rp "Enable auto-push to remote? [y/N] " enable_push
            if [[ "$enable_push" =~ ^[Yy]$ ]]; then
                ENABLE_AUTO_PUSH=true
                success "Auto-push enabled"
            else
                ENABLE_AUTO_PUSH=false
                log "Auto-push disabled (local commits only)"
            fi
            echo ""
            
            install_timer
            echo ""
            echo "To view logs:"
            echo "  journalctl --user -u $SERVICE_NAME.service -f"
            ;;
        remove)
            remove_timer
            ;;
        status)
            show_status
            ;;
        test)
            test_sync
            ;;
        logs)
            view_logs
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
