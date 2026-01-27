#!/bin/bash
# -----------------------------------------------------
# RESTORE PACKAGES
# -----------------------------------------------------
# Installs packages from state files
# Idempotent - skips already installed packages

# Don't exit on error - continue and report failures
# set -e

# Track failures
PACKAGE_FAILURES=()
PACKAGE_SUCCESSES=0

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
# Restore Pacman Mirrorlist
# -----------------------------------------------------
restore_mirrorlist() {
    local mirrorlist_file="$STATE_DIR/mirrorlist"
    
    if [ ! -f "$mirrorlist_file" ]; then
        log "No mirrorlist file found in state, keeping default"
        return 0
    fi
    
    log "Restoring pacman mirrorlist..."
    
    # Backup current mirrorlist
    if [ -f /etc/pacman.d/mirrorlist ]; then
        sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
    fi
    
    # Restore mirrorlist
    sudo cp "$mirrorlist_file" /etc/pacman.d/mirrorlist
    
    local count
    count=$(grep -c "^Server" /etc/pacman.d/mirrorlist 2>/dev/null || echo "0")
    success "Restored mirrorlist ($count mirrors)"
}

# -----------------------------------------------------
# Restore Custom Pacman Repositories
# -----------------------------------------------------
restore_pacman_repos() {
    local repos_file="$STATE_DIR/pacman-repos.conf"
    
    if [ ! -f "$repos_file" ]; then
        log "No custom pacman repos file found"
        return 0
    fi
    
    # Check if there are any actual repos (not just comments)
    local repo_count
    repo_count=$(grep -c '^\[' "$repos_file" 2>/dev/null || echo "0")
    
    if [ "$repo_count" -eq 0 ]; then
        log "No custom repositories to restore"
        return 0
    fi
    
    log "Restoring $repo_count custom pacman repositories..."
    
    # Check which repos are already in pacman.conf
    local repos_to_add=""
    local already_configured=0
    
    while IFS= read -r line; do
        if [[ "$line" =~ ^\[([a-zA-Z0-9_-]+)\]$ ]]; then
            local repo_name="${BASH_REMATCH[1]}"
            if grep -q "^\[$repo_name\]" /etc/pacman.conf 2>/dev/null; then
                log "  Repository [$repo_name] already configured"
                ((already_configured++)) || true
            else
                log "  Adding repository [$repo_name]"
                repos_to_add+="$line"$'\n'
            fi
        elif [[ -n "$repos_to_add" ]]; then
            # Continue adding lines for the current repo section
            repos_to_add+="$line"$'\n'
        fi
    done < <(grep -v '^#' "$repos_file" | grep -v '^$')
    
    if [ -z "$repos_to_add" ]; then
        success "All custom repositories already configured"
        return 0
    fi
    
    # Append new repos to pacman.conf
    echo "" | sudo tee -a /etc/pacman.conf > /dev/null
    echo "# Custom repositories added by dotfiles restore" | sudo tee -a /etc/pacman.conf > /dev/null
    echo "$repos_to_add" | sudo tee -a /etc/pacman.conf > /dev/null
    
    # Sync package databases
    log "Syncing package databases..."
    sudo pacman -Sy
    
    success "Custom repositories restored and synced"
}

# -----------------------------------------------------
# Install Pacman Packages
# -----------------------------------------------------
install_pacman_packages() {
    local packages_file="$STATE_DIR/packages-pacman.txt"
    
    if [ ! -f "$packages_file" ]; then
        warn "No pacman packages file found: $packages_file"
        return 0
    fi
    
    log "Installing pacman packages..."
    
    # Read packages into array, filtering empty lines and comments
    local packages=()
    while IFS= read -r pkg; do
        # Skip empty lines and comments
        [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue
        packages+=("$pkg")
    done < "$packages_file"
    
    if [ ${#packages[@]} -eq 0 ]; then
        warn "No packages to install from pacman list"
        return 0
    fi
    
    log "Found ${#packages[@]} packages in list"
    
    # Get currently installed packages
    local installed
    installed=$(pacman -Qq 2>/dev/null || echo "")
    
    # Filter to only packages not already installed
    local to_install=()
    for pkg in "${packages[@]}"; do
        if ! echo "$installed" | grep -qx "$pkg"; then
            to_install+=("$pkg")
        fi
    done
    
    if [ ${#to_install[@]} -eq 0 ]; then
        success "All pacman packages already installed"
        return 0
    fi
    
    log "Installing ${#to_install[@]} new packages..."
    
    # Install packages (--needed will skip already installed ones as extra safety)
    if sudo pacman -S --needed --noconfirm "${to_install[@]}"; then
        success "Installed ${#to_install[@]} pacman packages"
    else
        error "Some packages failed to install"
        return 1
    fi
}

# -----------------------------------------------------
# Install AUR Packages
# -----------------------------------------------------
install_aur_packages() {
    local packages_file="$STATE_DIR/packages-aur.txt"
    
    if [ ! -f "$packages_file" ]; then
        warn "No AUR packages file found: $packages_file"
        return 0
    fi
    
    # Check for AUR helper
    local aur_helper=""
    if command -v yay &> /dev/null; then
        aur_helper="yay"
    elif command -v paru &> /dev/null; then
        aur_helper="paru"
    else
        warn "No AUR helper found (yay/paru). Skipping AUR packages."
        warn "Install yay first: https://github.com/Jguer/yay"
        return 0
    fi
    
    log "Installing AUR packages with $aur_helper..."
    
    # Read packages into array
    local packages=()
    while IFS= read -r pkg; do
        [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue
        packages+=("$pkg")
    done < "$packages_file"
    
    if [ ${#packages[@]} -eq 0 ]; then
        warn "No AUR packages to install"
        return 0
    fi
    
    log "Found ${#packages[@]} AUR packages in list"
    
    # Get currently installed packages
    local installed
    installed=$(pacman -Qq 2>/dev/null || echo "")
    
    # Filter to only packages not already installed
    local to_install=()
    for pkg in "${packages[@]}"; do
        if ! echo "$installed" | grep -qx "$pkg"; then
            to_install+=("$pkg")
        fi
    done
    
    if [ ${#to_install[@]} -eq 0 ]; then
        success "All AUR packages already installed"
        return 0
    fi
    
    log "Installing ${#to_install[@]} new AUR packages..."
    
    # Install AUR packages one by one to continue on failure
    local failed=()
    local succeeded=0
    
    for pkg in "${to_install[@]}"; do
        log "Installing AUR package: $pkg"
        if $aur_helper -S --needed --noconfirm "$pkg" 2>&1; then
            ((succeeded++)) || true
        else
            warn "Failed to install: $pkg"
            failed+=("$pkg")
            PACKAGE_FAILURES+=("AUR: $pkg")
        fi
    done
    
    if [ ${#failed[@]} -eq 0 ]; then
        success "Installed $succeeded AUR packages"
    else
        warn "Installed $succeeded AUR packages, ${#failed[@]} failed"
        echo "  Failed packages: ${failed[*]}"
    fi
}

# -----------------------------------------------------
# Main
# -----------------------------------------------------
main() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  Restore Packages${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    check_sudo
    
    restore_mirrorlist
    restore_pacman_repos
    install_pacman_packages
    install_aur_packages
    
    echo ""
    
    # Show summary
    if [ ${#PACKAGE_FAILURES[@]} -eq 0 ]; then
        echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}  Package restoration complete!${NC}"
        echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    else
        echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
        echo -e "${YELLOW}  Package restoration completed with errors${NC}"
        echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
        echo ""
        echo -e "${RED}Failed packages:${NC}"
        for pkg in "${PACKAGE_FAILURES[@]}"; do
            echo -e "  ${RED}✗${NC} $pkg"
        done
        echo ""
        echo "You can try installing these manually later."
    fi
    echo ""
    
    # Return error if there were failures
    if [ ${#PACKAGE_FAILURES[@]} -gt 0 ]; then
        return 1
    fi
}

main "$@"
