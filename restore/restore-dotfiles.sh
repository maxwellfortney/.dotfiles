#!/bin/bash
# -----------------------------------------------------
# RESTORE DOTFILES
# -----------------------------------------------------
# Stows all dotfiles and handles secrets setup
# Idempotent - stow handles existing symlinks gracefully

# Don't exit on error - continue and report failures
# set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

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

# Directories to skip when stowing
SKIP_DIRS=(
    "restore"
    "scripts"
    "state"
    "logs"
    "tests"
    "vm"
    ".git"
)

should_skip() {
    local dir="$1"
    for skip in "${SKIP_DIRS[@]}"; do
        if [ "$dir" = "$skip" ]; then
            return 0
        fi
    done
    return 1
}

# -----------------------------------------------------
# Check Dependencies
# -----------------------------------------------------
check_dependencies() {
    if ! command -v stow &> /dev/null; then
        error "GNU Stow is not installed!"
        echo "Install it with: sudo pacman -S stow"
        exit 1
    fi
    success "GNU Stow is installed"
}

# -----------------------------------------------------
# Stow All Packages
# -----------------------------------------------------
stow_packages() {
    log "Stowing dotfiles packages..."
    log "Source: $DOTFILES_DIR"
    log "Target: $HOME"
    
    cd "$DOTFILES_DIR"
    
    local count=0
    local failed=0
    
    for dir in */; do
        # Remove trailing slash
        dir="${dir%/}"
        
        # Skip non-stow directories
        if should_skip "$dir"; then
            continue
        fi
        
        # Skip if not a directory
        [ ! -d "$dir" ] && continue
        
        log "Stowing $dir..."
        
        # Explicitly set target to $HOME (important when running from /mnt/dotfiles)
        if stow --target="$HOME" --restow "$dir" 2>&1; then
            success "Stowed: $dir"
            ((count++)) || true
        else
            # Try with --adopt to handle existing files
            warn "Conflict in $dir, trying with --adopt..."
            if stow --target="$HOME" --adopt --restow "$dir" 2>&1; then
                success "Stowed (adopted): $dir"
                ((count++)) || true
            else
                error "Failed to stow: $dir"
                ((failed++)) || true
            fi
        fi
    done
    
    log "Stowed $count packages ($failed failed)"
}

# -----------------------------------------------------
# Setup Secrets
# -----------------------------------------------------
setup_secrets() {
    log "Setting up secrets..."
    
    # Fish secrets
    local fish_secrets_example="$HOME/.config/fish/conf.d/99-secrets.fish.example"
    local fish_secrets="$HOME/.config/fish/conf.d/99-secrets.fish"
    
    if [ -f "$fish_secrets_example" ] && [ ! -f "$fish_secrets" ]; then
        warn "Fish secrets file not found"
        echo ""
        echo "  To set up fish secrets, run:"
        echo "  cp $fish_secrets_example $fish_secrets"
        echo "  Then edit $fish_secrets and add your tokens"
        echo ""
    elif [ -f "$fish_secrets" ]; then
        success "Fish secrets file exists"
    fi
    
    # SSH directory setup
    if [ ! -d "$HOME/.ssh" ]; then
        log "Creating .ssh directory..."
        mkdir -p "$HOME/.ssh"
        chmod 700 "$HOME/.ssh"
        success "Created .ssh directory"
        warn "Remember to restore your SSH keys!"
    else
        success ".ssh directory exists"
    fi
    
    # GPG directory setup
    if [ ! -d "$HOME/.gnupg" ]; then
        log "Creating .gnupg directory..."
        mkdir -p "$HOME/.gnupg"
        chmod 700 "$HOME/.gnupg"
        success "Created .gnupg directory"
        warn "Remember to restore your GPG keys!"
    else
        success ".gnupg directory exists"
    fi
}

# -----------------------------------------------------
# Post-Stow Actions
# -----------------------------------------------------
post_stow_actions() {
    log "Running post-stow actions..."
    
    # Ensure .local/bin is in PATH (for custom scripts)
    if [ -d "$HOME/.local/bin" ]; then
        success "\$HOME/.local/bin directory exists"
    fi
    
    # Set up font cache if fonts were stowed
    if [ -d "$HOME/.local/share/fonts" ]; then
        log "Updating font cache..."
        if fc-cache -f 2>/dev/null; then
            success "Font cache updated"
        else
            warn "Failed to update font cache (fc-cache not found?)"
        fi
    fi
    
    # Reload fish config if fish is the current shell
    if [ "$SHELL" = "/usr/bin/fish" ] || [ "$SHELL" = "/bin/fish" ]; then
        log "Fish shell detected - config will be loaded on next shell start"
    fi
}

# -----------------------------------------------------
# Main
# -----------------------------------------------------
main() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  Restore Dotfiles${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    check_dependencies
    stow_packages
    setup_secrets
    post_stow_actions
    
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Dotfiles restoration complete!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "Your dotfiles have been symlinked to your home directory."
    echo ""
    echo "Remember to:"
    echo "  - Set up your secrets file (see warnings above)"
    echo "  - Restore SSH and GPG keys from backup"
    echo "  - Log out and back in for all changes to take effect"
    echo ""
}

main "$@"
