#!/bin/bash
# -----------------------------------------------------
# ZERA - Dotfiles Installation (Stow)
# -----------------------------------------------------
# Symlinks configuration files to home directory using GNU Stow
# This script is sourced by install.sh

# Ensure common functions are available
[[ -z "${ZERA_COMMON_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/../helpers/common.sh"

log "Installing dotfiles..."

CONFIG_DIR="$(get_config_dir)"

# -----------------------------------------------------
# Directories to Skip
# -----------------------------------------------------
# These are not stow packages
SKIP_DIRS=(
    ".git"
    "install"
    "defaults"
    "docs"
)

should_skip() {
    local dir="$1"
    for skip in "${SKIP_DIRS[@]}"; do
        [[ "$dir" == "$skip" ]] && return 0
    done
    return 1
}

# -----------------------------------------------------
# Check Stow is Available
# -----------------------------------------------------

check_stow() {
    if ! has_command stow; then
        error "GNU Stow is not installed"
        echo "  This should have been installed in the packages step."
        return 1
    fi
    success "GNU Stow is available"
}

# -----------------------------------------------------
# Stow All Packages
# -----------------------------------------------------

stow_packages() {
    section "Stowing Configuration Packages"
    
    if [[ ! -d "$CONFIG_DIR" ]]; then
        error "Config directory not found: $CONFIG_DIR"
        return 1
    fi
    
    log "Source: $CONFIG_DIR"
    log "Target: $HOME"
    
    cd "$CONFIG_DIR" || return 1
    
    local count=0
    local failed=0
    local packages=()
    
    # Collect all stow packages
    for dir in */; do
        dir="${dir%/}"  # Remove trailing slash
        
        [[ ! -d "$dir" ]] && continue
        should_skip "$dir" && continue
        
        packages+=("$dir")
    done
    
    if [[ ${#packages[@]} -eq 0 ]]; then
        warn "No stow packages found in $CONFIG_DIR"
        return 0
    fi
    
    log "Found ${#packages[@]} packages to stow"
    
    if [[ "$DRY_RUN" == true ]]; then
        log "Would stow:"
        printf '  %s\n' "${packages[@]}"
        return 0
    fi
    
    # Stow each package
    for pkg in "${packages[@]}"; do
        log "Stowing $pkg..."
        
        # Try normal stow first
        if stow --target="$HOME" --restow "$pkg" 2>&1; then
            success "Stowed: $pkg"
            ((count++)) || true
        else
            # Try with --adopt to handle existing files
            warn "Conflict in $pkg, trying with --adopt..."
            if stow --target="$HOME" --adopt --restow "$pkg" 2>&1; then
                success "Stowed (adopted): $pkg"
                ((count++)) || true
            else
                error "Failed to stow: $pkg"
                ((failed++)) || true
            fi
        fi
    done
    
    cd - > /dev/null || true
    
    log "Stowed $count packages ($failed failed)"
    
    if [[ $failed -gt 0 ]]; then
        return 1
    fi
}

# -----------------------------------------------------
# Setup Secrets Template
# -----------------------------------------------------

setup_secrets() {
    section "Secrets Setup"
    
    # Fish secrets
    local fish_secrets_example="$HOME/.config/fish/conf.d/99-secrets.fish.example"
    local fish_secrets="$HOME/.config/fish/conf.d/99-secrets.fish"
    
    if [[ -f "$fish_secrets_example" ]] && [[ ! -f "$fish_secrets" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            log "Would create fish secrets file from template"
        else
            cp "$fish_secrets_example" "$fish_secrets"
            success "Created fish secrets file"
            info "Edit $fish_secrets to add your tokens"
        fi
    elif [[ -f "$fish_secrets" ]]; then
        success "Fish secrets file already exists"
    fi
    
    # Create SSH directory
    if [[ ! -d "$HOME/.ssh" ]]; then
        if [[ "$DRY_RUN" != true ]]; then
            mkdir -p "$HOME/.ssh"
            chmod 700 "$HOME/.ssh"
            success "Created .ssh directory"
        fi
        warn "Remember to restore your SSH keys!"
    else
        success ".ssh directory exists"
    fi
    
    # Create GPG directory
    if [[ ! -d "$HOME/.gnupg" ]]; then
        if [[ "$DRY_RUN" != true ]]; then
            mkdir -p "$HOME/.gnupg"
            chmod 700 "$HOME/.gnupg"
            success "Created .gnupg directory"
        fi
        warn "Remember to restore your GPG keys!"
    else
        success ".gnupg directory exists"
    fi
}

# -----------------------------------------------------
# Post-Stow Actions
# -----------------------------------------------------

post_stow() {
    section "Post-Stow Actions"
    
    # Ensure .local/bin exists
    ensure_dir "$HOME/.local/bin"
    success "\$HOME/.local/bin directory ready"
    
    # Update font cache if fonts were stowed
    if [[ -d "$HOME/.local/share/fonts" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            log "Would update font cache"
        else
            log "Updating font cache..."
            if fc-cache -f 2>/dev/null; then
                success "Font cache updated"
            else
                warn "Failed to update font cache"
            fi
        fi
    fi
}

# -----------------------------------------------------
# Run Installation
# -----------------------------------------------------

check_stow || exit 1
stow_packages
setup_secrets
post_stow

echo ""
success "Dotfiles installation complete!"
