#!/bin/bash
# -----------------------------------------------------
# INSTALL DEPENDENCIES
# -----------------------------------------------------
# Installs minimal dependencies required for restoration
# Run this first on a fresh Arch Linux installation

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Check if we're on Arch Linux
check_arch() {
    if [ ! -f /etc/arch-release ]; then
        error "This script is designed for Arch Linux"
        echo "You may need to adapt it for your distribution"
        exit 1
    fi
    success "Running on Arch Linux"
}

# Install a package if not already installed
install_if_missing() {
    local pkg="$1"
    if pacman -Qi "$pkg" &>/dev/null; then
        success "$pkg already installed"
    else
        log "Installing $pkg..."
        sudo pacman -S --noconfirm "$pkg"
        success "Installed $pkg"
    fi
}

# -----------------------------------------------------
# Install Essential Packages
# -----------------------------------------------------
install_essentials() {
    log "Installing essential packages..."
    
    # Core packages needed for restoration
    install_if_missing "git"
    install_if_missing "stow"
    install_if_missing "base-devel"  # Needed for AUR helper
}

# -----------------------------------------------------
# Install yay (AUR helper)
# -----------------------------------------------------
install_yay() {
    if command -v yay &> /dev/null; then
        success "yay already installed"
        return 0
    fi
    
    log "Installing yay (AUR helper)..."
    
    # Create temp directory
    local tmpdir
    tmpdir=$(mktemp -d)
    cd "$tmpdir"
    
    # Clone yay
    git clone https://aur.archlinux.org/yay.git
    cd yay
    
    # Build and install
    makepkg -si --noconfirm
    
    # Cleanup
    cd ~
    rm -rf "$tmpdir"
    
    success "Installed yay"
}

# -----------------------------------------------------
# Install Optional Packages
# -----------------------------------------------------
install_optional() {
    log "Installing optional helpful packages..."
    
    # fzf for interactive selection
    install_if_missing "fzf"
    
    # For font cache
    install_if_missing "fontconfig"
}

# -----------------------------------------------------
# Verify Installation
# -----------------------------------------------------
verify_installation() {
    log "Verifying installation..."
    
    local all_good=true
    
    if command -v git &> /dev/null; then
        success "git: $(git --version)"
    else
        error "git not found"
        all_good=false
    fi
    
    if command -v stow &> /dev/null; then
        success "stow: $(stow --version | head -1)"
    else
        error "stow not found"
        all_good=false
    fi
    
    if command -v yay &> /dev/null; then
        success "yay: $(yay --version)"
    else
        error "yay not found"
        all_good=false
    fi
    
    if [ "$all_good" = true ]; then
        success "All dependencies installed successfully"
        return 0
    else
        error "Some dependencies failed to install"
        return 1
    fi
}

# -----------------------------------------------------
# Main
# -----------------------------------------------------
main() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  Install Dependencies${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    check_arch
    
    # Refresh package database
    log "Refreshing package database..."
    sudo pacman -Sy
    
    install_essentials
    install_yay
    install_optional
    verify_installation
    
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Dependencies installed!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "You can now run the restoration:"
    echo "  ./restore/restore.sh"
    echo ""
}

main "$@"
