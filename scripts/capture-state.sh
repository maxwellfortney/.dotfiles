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
# Capture Custom Pacman Repositories
# -----------------------------------------------------
capture_pacman_repos() {
    log "Capturing custom pacman repositories..."
    
    local repos_file="$STATE_DIR/pacman-repos.conf"
    
    # Extract non-standard repo sections from pacman.conf
    # Standard repos are: core, extra, multilib, community (deprecated), testing variants
    local standard_repos="core|extra|multilib|community|testing|core-testing|extra-testing|multilib-testing|kde-unstable|gnome-unstable"
    
    {
        echo "# Custom pacman repositories"
        echo "# Generated: $(date)"
        echo "# Add these to /etc/pacman.conf before installing packages"
        echo ""
    } > "$repos_file"
    
    # Parse pacman.conf for custom repo sections
    local in_custom_repo=0
    local current_section=""
    
    while IFS= read -r line; do
        # Check for section headers
        if [[ "$line" =~ ^\[([a-zA-Z0-9_-]+)\]$ ]]; then
            current_section="${BASH_REMATCH[1]}"
            # Check if this is a custom repo (not standard)
            if [[ ! "$current_section" =~ ^($standard_repos)$ && "$current_section" != "options" ]]; then
                in_custom_repo=1
                echo "" >> "$repos_file"
                echo "$line" >> "$repos_file"
            else
                in_custom_repo=0
            fi
        elif [[ $in_custom_repo -eq 1 ]]; then
            # Copy lines from custom repo sections
            echo "$line" >> "$repos_file"
        fi
    done < /etc/pacman.conf
    
    # Count custom repos
    local count
    count=$(grep -c '^\[' "$repos_file" 2>/dev/null || echo "0")
    
    if [ "$count" -gt 0 ]; then
        success "Captured $count custom pacman repos -> pacman-repos.conf"
    else
        echo "# No custom repositories found" >> "$repos_file"
        success "No custom pacman repos found"
    fi
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
# Capture Pacman Mirrorlist
# -----------------------------------------------------
capture_mirrorlist() {
    log "Capturing pacman mirrorlist..."
    
    local mirrorlist_file="$STATE_DIR/mirrorlist"
    
    if [ -f /etc/pacman.d/mirrorlist ]; then
        cp /etc/pacman.d/mirrorlist "$mirrorlist_file"
        local count
        count=$(grep -c "^Server" "$mirrorlist_file" 2>/dev/null || echo "0")
        success "Captured mirrorlist ($count active mirrors)"
    else
        warn "No mirrorlist found at /etc/pacman.d/mirrorlist"
    fi
}

# -----------------------------------------------------
# Capture Custom Systemd Service Files
# -----------------------------------------------------
capture_custom_services() {
    log "Capturing custom systemd service files..."
    
    local services_dir="$STATE_DIR/systemd-services"
    local user_services_dir="$STATE_DIR/systemd-user-services"
    
    mkdir -p "$services_dir"
    mkdir -p "$user_services_dir"
    
    # Clear old files
    rm -f "$services_dir"/*.service "$services_dir"/*.timer 2>/dev/null || true
    rm -f "$user_services_dir"/*.service "$user_services_dir"/*.timer 2>/dev/null || true
    
    local count=0
    
    # Capture system-level custom services from /etc/systemd/system/
    # (excluding symlinks which are just enabled services pointing elsewhere)
    if [ -d /etc/systemd/system ]; then
        for unit in /etc/systemd/system/*.service /etc/systemd/system/*.timer; do
            if [ -f "$unit" ] && [ ! -L "$unit" ]; then
                cp "$unit" "$services_dir/"
                ((count++)) || true
                log "  Captured $(basename "$unit")"
            fi
        done
    fi
    
    # Also check for drop-in overrides
    for dir in /etc/systemd/system/*.d; do
        if [ -d "$dir" ]; then
            local unit_name
            unit_name=$(basename "$dir" .d)
            mkdir -p "$services_dir/${unit_name}.d"
            cp "$dir"/*.conf "$services_dir/${unit_name}.d/" 2>/dev/null || true
            log "  Captured overrides for $unit_name"
        fi
    done
    
    success "Captured $count custom system services -> systemd-services/"
    
    # Capture user-level custom services
    local user_count=0
    local user_systemd="$HOME/.config/systemd/user"
    
    if [ -d "$user_systemd" ]; then
        for unit in "$user_systemd"/*.service "$user_systemd"/*.timer; do
            if [ -f "$unit" ] && [ ! -L "$unit" ]; then
                cp "$unit" "$user_services_dir/"
                ((user_count++)) || true
                log "  Captured user $(basename "$unit")"
            fi
        done
    fi
    
    success "Captured $user_count custom user services -> systemd-user-services/"
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
    
    capture_pacman_repos
    capture_pacman_packages
    capture_aur_packages
    capture_system_services
    capture_user_services
    capture_mkinitcpio
    capture_kernel_params
    capture_sysctl
    capture_system_info
    capture_mirrorlist
    capture_custom_services
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
