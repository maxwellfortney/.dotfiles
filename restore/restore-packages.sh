#!/bin/bash
# -----------------------------------------------------
# RESTORE PACKAGES
# -----------------------------------------------------
# Installs packages from state files
# Idempotent - skips already installed packages

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
    
    # Install AUR packages
    if $aur_helper -S --needed --noconfirm "${to_install[@]}"; then
        success "Installed ${#to_install[@]} AUR packages"
    else
        error "Some AUR packages failed to install"
        return 1
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
    
    install_pacman_packages
    install_aur_packages
    
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Package restoration complete!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

main "$@"
