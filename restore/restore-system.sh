#!/bin/bash
# -----------------------------------------------------
# RESTORE SYSTEM CONFIGURATION
# -----------------------------------------------------
# Restores system-level configurations:
# - mkinitcpio.conf
# - Kernel parameters
# - Sysctl settings
# - Hostname, locale, timezone
# - User groups
#
# Idempotent - checks current state before making changes

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

# Check if running with sudo available
check_sudo() {
    if ! sudo -v &>/dev/null; then
        error "This script requires sudo access"
        exit 1
    fi
}

# -----------------------------------------------------
# Restore mkinitcpio.conf
# -----------------------------------------------------
restore_mkinitcpio() {
    local mkinitcpio_file="$STATE_DIR/mkinitcpio.conf"
    
    if [ ! -f "$mkinitcpio_file" ]; then
        warn "No mkinitcpio.conf in state directory"
        return 0
    fi
    
    # Check if it's just a placeholder
    if grep -q "^# mkinitcpio.conf not found" "$mkinitcpio_file"; then
        log "mkinitcpio.conf is a placeholder, skipping"
        return 0
    fi
    
    log "Checking mkinitcpio.conf..."
    
    if [ ! -f /etc/mkinitcpio.conf ]; then
        warn "System doesn't have /etc/mkinitcpio.conf (different init system?)"
        return 0
    fi
    
    # Compare files
    if diff -q "$mkinitcpio_file" /etc/mkinitcpio.conf &>/dev/null; then
        success "mkinitcpio.conf already matches"
        return 0
    fi
    
    log "Updating mkinitcpio.conf..."
    
    # Backup current config
    sudo cp /etc/mkinitcpio.conf /etc/mkinitcpio.conf.backup
    
    # Copy new config
    sudo cp "$mkinitcpio_file" /etc/mkinitcpio.conf
    
    success "Restored mkinitcpio.conf (backup at /etc/mkinitcpio.conf.backup)"
    
    # Regenerate initramfs
    log "Regenerating initramfs..."
    if sudo mkinitcpio -P; then
        success "Regenerated initramfs"
    else
        error "Failed to regenerate initramfs"
        warn "You may need to run 'sudo mkinitcpio -P' manually"
    fi
}

# -----------------------------------------------------
# Restore Sysctl Settings
# -----------------------------------------------------
restore_sysctl() {
    local sysctl_file="$STATE_DIR/sysctl.conf"
    
    if [ ! -f "$sysctl_file" ]; then
        warn "No sysctl.conf in state directory"
        return 0
    fi
    
    log "Checking sysctl settings..."
    
    # Check if file has actual settings (not just comments)
    local settings
    settings=$(grep -v "^#" "$sysctl_file" | grep -v "^$" || true)
    
    if [ -z "$settings" ]; then
        log "No custom sysctl settings to restore"
        return 0
    fi
    
    # Create a sysctl.d file for our settings
    local target="/etc/sysctl.d/99-dotfiles.conf"
    
    if [ -f "$target" ] && diff -q <(grep -v "^#" "$sysctl_file" | grep -v "^$" | sort) <(grep -v "^#" "$target" | grep -v "^$" | sort) &>/dev/null; then
        success "Sysctl settings already applied"
        return 0
    fi
    
    log "Applying sysctl settings..."
    
    {
        echo "# Dotfiles sysctl settings"
        echo "# Generated from state/sysctl.conf"
        echo ""
        echo "$settings"
    } | sudo tee "$target" > /dev/null
    
    # Apply settings
    sudo sysctl --system &>/dev/null
    
    success "Applied sysctl settings to $target"
}

# -----------------------------------------------------
# Restore System Info (hostname, locale, timezone)
# -----------------------------------------------------
restore_system_info() {
    local info_file="$STATE_DIR/system-info.txt"
    
    if [ ! -f "$info_file" ]; then
        warn "No system-info.txt in state directory"
        return 0
    fi
    
    log "Checking system info..."
    
    # Parse system info file
    local saved_hostname saved_timezone saved_lang saved_groups saved_shell
    saved_hostname=$(grep "^HOSTNAME=" "$info_file" | cut -d= -f2)
    saved_timezone=$(grep "^TIMEZONE=" "$info_file" | cut -d= -f2)
    saved_lang=$(grep "^LANG=" "$info_file" | cut -d= -f2)
    saved_groups=$(grep "^GROUPS=" "$info_file" | cut -d= -f2)
    saved_shell=$(grep "^SHELL=" "$info_file" | cut -d= -f2)
    
    # Restore hostname
    if [ -n "$saved_hostname" ] && [ "$saved_hostname" != "$(hostname)" ]; then
        log "Setting hostname to: $saved_hostname"
        sudo hostnamectl set-hostname "$saved_hostname"
        success "Hostname set to $saved_hostname"
    else
        success "Hostname already correct"
    fi
    
    # Restore timezone
    if [ -n "$saved_timezone" ] && [ "$saved_timezone" != "unknown" ]; then
        local current_tz
        current_tz=$(timedatectl show --property=Timezone --value 2>/dev/null || echo "")
        if [ "$saved_timezone" != "$current_tz" ]; then
            log "Setting timezone to: $saved_timezone"
            sudo timedatectl set-timezone "$saved_timezone"
            success "Timezone set to $saved_timezone"
        else
            success "Timezone already correct"
        fi
    fi
    
    # Restore locale
    if [ -n "$saved_lang" ]; then
        local current_lang="${LANG:-}"
        if [ "$saved_lang" != "$current_lang" ]; then
            log "Setting LANG to: $saved_lang"
            echo "LANG=$saved_lang" | sudo tee /etc/locale.conf > /dev/null
            success "Locale set to $saved_lang"
            warn "You may need to regenerate locales with: sudo locale-gen"
        else
            success "Locale already correct"
        fi
    fi
    
    # Restore user groups
    if [ -n "$saved_groups" ]; then
        log "Checking user groups..."
        
        # Parse saved groups (comma-separated)
        IFS=',' read -ra group_array <<< "$saved_groups"
        
        for group in "${group_array[@]}"; do
            group=$(echo "$group" | tr -d ' ')
            [ -z "$group" ] && continue
            
            # Skip if user already in group
            if groups "$USER" 2>/dev/null | grep -qw "$group"; then
                continue
            fi
            
            # Check if group exists
            if getent group "$group" &>/dev/null; then
                log "Adding user to group: $group"
                sudo usermod -aG "$group" "$USER"
                success "Added to group: $group"
            else
                warn "Group does not exist: $group"
            fi
        done
        
        success "User groups checked"
    fi
    
    # Restore default shell
    if [ -n "$saved_shell" ] && [ -x "$saved_shell" ]; then
        local current_shell
        current_shell=$(getent passwd "$USER" | cut -d: -f7)
        if [ "$saved_shell" != "$current_shell" ]; then
            log "Changing default shell to: $saved_shell"
            sudo chsh -s "$saved_shell" "$USER"
            success "Default shell set to $saved_shell"
        else
            success "Default shell already correct"
        fi
    fi
}

# -----------------------------------------------------
# Main
# -----------------------------------------------------
main() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  Restore System Configuration${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    check_sudo
    
    restore_mkinitcpio
    restore_sysctl
    restore_system_info
    
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  System configuration restoration complete!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "Note: Some changes (like group membership) require logout/login to take effect."
    echo ""
}

main "$@"
