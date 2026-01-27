#!/bin/bash
# -----------------------------------------------------
# RESTORE SERVICES
# -----------------------------------------------------
# Enables systemd services from state files
# Idempotent - skips already enabled services

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
STATE_DIR="$DOTFILES_DIR/state"

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

# Services to skip (system-critical or auto-enabled)
SKIP_SERVICES=(
    "dbus.service"
    "systemd-journald.service"
    "systemd-logind.service"
    "systemd-udevd.service"
    "systemd-timesyncd.service"
    "getty@.service"
    "getty@tty1.service"
    "autovt@.service"
)

should_skip() {
    local service="$1"
    for skip in "${SKIP_SERVICES[@]}"; do
        if [ "$service" = "$skip" ]; then
            return 0
        fi
    done
    return 1
}

# -----------------------------------------------------
# Enable System Services
# -----------------------------------------------------
enable_system_services() {
    local services_file="$STATE_DIR/services-enabled.txt"
    
    if [ ! -f "$services_file" ]; then
        warn "No system services file found: $services_file"
        return 0
    fi
    
    log "Enabling system services..."
    
    # Get currently enabled services
    local enabled
    enabled=$(systemctl list-unit-files --state=enabled --type=service --no-legend 2>/dev/null | awk '{print $1}')
    
    local count=0
    local skipped=0
    local already=0
    
    while IFS= read -r service; do
        # Skip empty lines and comments
        [[ -z "$service" || "$service" =~ ^# ]] && continue
        
        # Skip system-critical services
        if should_skip "$service"; then
            ((skipped++))
            continue
        fi
        
        # Check if already enabled
        if echo "$enabled" | grep -qx "$service"; then
            ((already++))
            continue
        fi
        
        # Try to enable the service
        if sudo systemctl enable "$service" 2>/dev/null; then
            success "Enabled: $service"
            ((count++))
        else
            warn "Failed to enable: $service (may not exist)"
        fi
    done < "$services_file"
    
    log "System services: $count enabled, $already already enabled, $skipped skipped"
}

# -----------------------------------------------------
# Enable User Services
# -----------------------------------------------------
enable_user_services() {
    local services_file="$STATE_DIR/services-user.txt"
    
    if [ ! -f "$services_file" ]; then
        warn "No user services file found: $services_file"
        return 0
    fi
    
    log "Enabling user services..."
    
    # Get currently enabled user services
    local enabled
    enabled=$(systemctl --user list-unit-files --state=enabled --type=service --no-legend 2>/dev/null | awk '{print $1}')
    
    local count=0
    local already=0
    
    while IFS= read -r service; do
        # Skip empty lines and comments
        [[ -z "$service" || "$service" =~ ^# ]] && continue
        
        # Check if already enabled
        if echo "$enabled" | grep -qx "$service"; then
            ((already++))
            continue
        fi
        
        # Try to enable the service
        if systemctl --user enable "$service" 2>/dev/null; then
            success "Enabled user service: $service"
            ((count++))
        else
            warn "Failed to enable user service: $service (may not exist)"
        fi
    done < "$services_file"
    
    log "User services: $count enabled, $already already enabled"
}

# -----------------------------------------------------
# Enable Timers
# -----------------------------------------------------
enable_timers() {
    local timers_file="$STATE_DIR/timers-enabled.txt"
    
    if [ ! -f "$timers_file" ]; then
        log "No system timers file found (optional)"
        return 0
    fi
    
    log "Enabling system timers..."
    
    local enabled
    enabled=$(systemctl list-unit-files --state=enabled --type=timer --no-legend 2>/dev/null | awk '{print $1}')
    
    local count=0
    
    while IFS= read -r timer; do
        [[ -z "$timer" || "$timer" =~ ^# ]] && continue
        
        if echo "$enabled" | grep -qx "$timer"; then
            continue
        fi
        
        if sudo systemctl enable "$timer" 2>/dev/null; then
            success "Enabled timer: $timer"
            ((count++))
        fi
    done < "$timers_file"
    
    log "Enabled $count system timers"
}

# -----------------------------------------------------
# Enable User Timers
# -----------------------------------------------------
enable_user_timers() {
    local timers_file="$STATE_DIR/timers-user.txt"
    
    if [ ! -f "$timers_file" ]; then
        log "No user timers file found (optional)"
        return 0
    fi
    
    log "Enabling user timers..."
    
    local enabled
    enabled=$(systemctl --user list-unit-files --state=enabled --type=timer --no-legend 2>/dev/null | awk '{print $1}')
    
    local count=0
    
    while IFS= read -r timer; do
        [[ -z "$timer" || "$timer" =~ ^# ]] && continue
        
        if echo "$enabled" | grep -qx "$timer"; then
            continue
        fi
        
        if systemctl --user enable "$timer" 2>/dev/null; then
            success "Enabled user timer: $timer"
            ((count++))
        fi
    done < "$timers_file"
    
    log "Enabled $count user timers"
}

# -----------------------------------------------------
# Main
# -----------------------------------------------------
main() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  Restore Services${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    enable_system_services
    enable_user_services
    enable_timers
    enable_user_timers
    
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Service restoration complete!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "Note: Services have been enabled but may need a reboot to start."
    echo "Or start them manually with: sudo systemctl start <service>"
    echo ""
}

main "$@"
