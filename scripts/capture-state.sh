#!/bin/bash
# -----------------------------------------------------
# CAPTURE STATE
# -----------------------------------------------------
# Captures current system state and saves to state/ directory
# Run this script to update state files before committing
# This script is idempotent - safe to run multiple times

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get script directory (resolve symlinks)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
STATE_DIR="$DOTFILES_DIR/state"

# Ensure state directory exists
mkdir -p "$STATE_DIR"

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
# Capture Pacman Packages
# -----------------------------------------------------
capture_pacman_packages() {
    log "Capturing pacman packages..."
    
    # Get explicitly installed packages (not dependencies)
    # Filter out AUR packages by checking against pacman repos
    local pacman_file="$STATE_DIR/packages-pacman.txt"
    
    # Get all explicitly installed packages
    pacman -Qqe > /tmp/all-explicit.txt
    
    # Get packages available in repos (non-AUR)
    pacman -Slq > /tmp/repo-packages.txt 2>/dev/null || true
    
    # Filter to only repo packages
    grep -Fxf /tmp/repo-packages.txt /tmp/all-explicit.txt > "$pacman_file" 2>/dev/null || true
    
    # Cleanup
    rm -f /tmp/all-explicit.txt /tmp/repo-packages.txt
    
    local count
    count=$(wc -l < "$pacman_file" | tr -d ' ')
    success "Captured $count pacman packages -> packages-pacman.txt"
}

# -----------------------------------------------------
# Capture AUR Packages
# -----------------------------------------------------
capture_aur_packages() {
    log "Capturing AUR packages..."
    
    local aur_file="$STATE_DIR/packages-aur.txt"
    
    local count
    if command -v yay &> /dev/null; then
        # Get foreign packages (not in official repos) = AUR packages
        pacman -Qqem > "$aur_file" 2>/dev/null || echo "" > "$aur_file"
        count=$(wc -l < "$aur_file" | tr -d ' ')
        success "Captured $count AUR packages -> packages-aur.txt"
    elif command -v paru &> /dev/null; then
        pacman -Qqem > "$aur_file" 2>/dev/null || echo "" > "$aur_file"
        count=$(wc -l < "$aur_file" | tr -d ' ')
        success "Captured $count AUR packages -> packages-aur.txt"
    else
        warn "No AUR helper found (yay/paru), capturing foreign packages anyway"
        pacman -Qqem > "$aur_file" 2>/dev/null || echo "" > "$aur_file"
    fi
}

# -----------------------------------------------------
# Capture Enabled System Services
# -----------------------------------------------------
capture_system_services() {
    log "Capturing enabled system services..."
    
    local services_file="$STATE_DIR/services-enabled.txt"
    
    # Get enabled services (system-wide)
    systemctl list-unit-files --state=enabled --type=service --no-legend 2>/dev/null | \
        awk '{print $1}' | \
        sort > "$services_file"
    
    local count
    count=$(wc -l < "$services_file" | tr -d ' ')
    success "Captured $count enabled system services -> services-enabled.txt"
}

# -----------------------------------------------------
# Capture Enabled User Services
# -----------------------------------------------------
capture_user_services() {
    log "Capturing enabled user services..."
    
    local user_services_file="$STATE_DIR/services-user.txt"
    
    # Get enabled user services
    systemctl --user list-unit-files --state=enabled --type=service --no-legend 2>/dev/null | \
        awk '{print $1}' | \
        sort > "$user_services_file"
    
    local count
    count=$(wc -l < "$user_services_file" | tr -d ' ')
    success "Captured $count enabled user services -> services-user.txt"
}

# -----------------------------------------------------
# Capture mkinitcpio Configuration
# -----------------------------------------------------
capture_mkinitcpio() {
    log "Capturing mkinitcpio configuration..."
    
    local mkinitcpio_file="$STATE_DIR/mkinitcpio.conf"
    
    if [ -f /etc/mkinitcpio.conf ]; then
        cp /etc/mkinitcpio.conf "$mkinitcpio_file"
        success "Captured mkinitcpio.conf"
    else
        warn "No /etc/mkinitcpio.conf found (maybe not using mkinitcpio?)"
        echo "# mkinitcpio.conf not found on this system" > "$mkinitcpio_file"
    fi
}

# -----------------------------------------------------
# Capture Kernel Parameters
# -----------------------------------------------------
capture_kernel_params() {
    log "Capturing kernel parameters..."
    
    local kernel_file="$STATE_DIR/kernel-params.txt"
    
    # Capture current kernel command line
    echo "# Current kernel command line (from /proc/cmdline)" > "$kernel_file"
    cat /proc/cmdline >> "$kernel_file"
    echo "" >> "$kernel_file"
    
    # Capture GRUB defaults if available
    if [ -f /etc/default/grub ]; then
        echo "# GRUB defaults (/etc/default/grub)" >> "$kernel_file"
        grep -E "^GRUB_CMDLINE_LINUX" /etc/default/grub >> "$kernel_file" 2>/dev/null || true
    fi
    
    # Capture systemd-boot entries if available
    if [ -d /boot/loader/entries ]; then
        echo "" >> "$kernel_file"
        echo "# systemd-boot entries found in /boot/loader/entries/" >> "$kernel_file"
        for entry in /boot/loader/entries/*.conf; do
            if [ -f "$entry" ]; then
                echo "# --- $(basename "$entry") ---" >> "$kernel_file"
                grep -E "^options" "$entry" >> "$kernel_file" 2>/dev/null || true
            fi
        done
    fi
    
    success "Captured kernel parameters -> kernel-params.txt"
}

# -----------------------------------------------------
# Capture Sysctl Settings
# -----------------------------------------------------
capture_sysctl() {
    log "Capturing sysctl settings..."
    
    local sysctl_file="$STATE_DIR/sysctl.conf"
    
    # Capture custom sysctl files
    echo "# Custom sysctl settings" > "$sysctl_file"
    
    if [ -f /etc/sysctl.conf ]; then
        echo "# From /etc/sysctl.conf:" >> "$sysctl_file"
        grep -v "^#" /etc/sysctl.conf | grep -v "^$" >> "$sysctl_file" 2>/dev/null || true
    fi
    
    if [ -d /etc/sysctl.d ]; then
        for conf in /etc/sysctl.d/*.conf; do
            if [ -f "$conf" ]; then
                echo "" >> "$sysctl_file"
                echo "# From $(basename "$conf"):" >> "$sysctl_file"
                grep -v "^#" "$conf" | grep -v "^$" >> "$sysctl_file" 2>/dev/null || true
            fi
        done
    fi
    
    success "Captured sysctl settings -> sysctl.conf"
}

# -----------------------------------------------------
# Capture System Info
# -----------------------------------------------------
capture_system_info() {
    log "Capturing system information..."
    
    local info_file="$STATE_DIR/system-info.txt"
    
    {
        echo "# System Information"
        echo "# Generated: $(date)"
        echo ""
        
        echo "# Hostname"
        if command -v hostnamectl &>/dev/null; then
            echo "HOSTNAME=$(hostnamectl --static 2>/dev/null || hostname)"
        else
            echo "HOSTNAME=$(hostname)"
        fi
        echo ""
        
        echo "# Timezone"
        echo "TIMEZONE=$(timedatectl show --property=Timezone --value 2>/dev/null || cat /etc/timezone 2>/dev/null || echo 'unknown')"
        echo ""
        
        echo "# Locale"
        echo "LANG=${LANG:-$(locale | grep LANG= | cut -d= -f2)}"
        if [ -f /etc/locale.conf ]; then
            echo "# /etc/locale.conf:"
            cat /etc/locale.conf | sed 's/^/# /'
        fi
        echo ""
        
        echo "# User groups for $USER"
        echo "GROUPS=$(groups "$USER" 2>/dev/null | cut -d: -f2 | tr -d ' ' | tr ' ' ',')"
        echo ""
        
        echo "# Default shell"
        echo "SHELL=$(getent passwd "$USER" | cut -d: -f7)"
        echo ""
        
        echo "# Boot loader"
        if [ -d /boot/loader ]; then
            echo "BOOTLOADER=systemd-boot"
        elif [ -d /boot/grub ]; then
            echo "BOOTLOADER=grub"
        else
            echo "BOOTLOADER=unknown"
        fi
        
    } > "$info_file"
    
    success "Captured system info -> system-info.txt"
}

# -----------------------------------------------------
# Capture Additional Configs
# -----------------------------------------------------
capture_additional() {
    log "Capturing additional configurations..."
    
    # Capture enabled timers
    local timers_file="$STATE_DIR/timers-enabled.txt"
    systemctl list-unit-files --state=enabled --type=timer --no-legend 2>/dev/null | \
        awk '{print $1}' | \
        sort > "$timers_file"
    success "Captured enabled timers -> timers-enabled.txt"
    
    # Capture user timers
    local user_timers_file="$STATE_DIR/timers-user.txt"
    systemctl --user list-unit-files --state=enabled --type=timer --no-legend 2>/dev/null | \
        awk '{print $1}' | \
        sort > "$user_timers_file"
    success "Captured user timers -> timers-user.txt"
}

# -----------------------------------------------------
# Main
# -----------------------------------------------------
main() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  Dotfiles State Capture${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    log "State directory: $STATE_DIR"
    echo ""
    
    capture_pacman_packages
    capture_aur_packages
    capture_system_services
    capture_user_services
    capture_mkinitcpio
    capture_kernel_params
    capture_sysctl
    capture_system_info
    capture_additional
    
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  State capture complete!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "State files saved to: $STATE_DIR"
    echo ""
    echo "To commit these changes:"
    echo "  cd $DOTFILES_DIR"
    echo "  git add state/"
    echo "  git commit -m 'Update system state'"
    echo ""
}

main "$@"
