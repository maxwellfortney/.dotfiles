#!/bin/bash
# -----------------------------------------------------
# ZERA - Post-Installation Tasks
# -----------------------------------------------------
# Final cleanup and theme application
# This script is sourced by install.sh

# Ensure common functions are available
[[ -z "${ZERA_COMMON_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/../helpers/common.sh"

log "Running post-installation tasks..."

# -----------------------------------------------------
# Apply Initial Theme (if matugen installed)
# -----------------------------------------------------

apply_theme() {
    section "Theme Setup"
    
    if ! has_command matugen; then
        info "matugen not installed, skipping theme setup"
        info "Install from AUR: yay -S matugen-bin"
        return 0
    fi
    
    # Check for wallpapers in config
    local wallpaper_dir="$HOME/.config/wallpapers"
    local zera_wallpapers="$(get_zera_dir)/config/wallpapers"
    
    # Copy wallpapers if they exist in zera config but not in home
    if [[ -d "$zera_wallpapers" ]] && [[ ! -d "$wallpaper_dir" ]]; then
        if [[ "$DRY_RUN" != true ]]; then
            mkdir -p "$wallpaper_dir"
            cp -r "$zera_wallpapers"/* "$wallpaper_dir/" 2>/dev/null || true
            success "Copied default wallpapers"
        fi
    fi
    
    # Find a wallpaper to use
    local wallpaper=""
    if [[ -d "$wallpaper_dir" ]]; then
        wallpaper=$(find "$wallpaper_dir" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.webp" \) | head -1)
    fi
    
    if [[ -z "$wallpaper" ]]; then
        info "No wallpapers found, skipping theme generation"
        info "Run 'change-theme <wallpaper>' later to set theme"
        return 0
    fi
    
    if [[ "$DRY_RUN" == true ]]; then
        log "Would apply theme from: $wallpaper"
        return 0
    fi
    
    log "Generating theme from: $(basename "$wallpaper")"
    
    # Run matugen to generate theme
    if matugen image "$wallpaper" 2>/dev/null; then
        success "Theme generated successfully"
    else
        warn "Theme generation failed"
        info "Try running 'matugen image <wallpaper>' manually"
    fi
}

# -----------------------------------------------------
# Create Helper Scripts
# -----------------------------------------------------

create_helper_scripts() {
    section "Helper Scripts"
    
    local bin_dir="$HOME/.local/bin"
    ensure_dir "$bin_dir"
    
    # Create change-theme helper if it doesn't exist
    local change_theme="$bin_dir/change-theme"
    
    if [[ ! -f "$change_theme" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            log "Would create change-theme helper script"
        else
            cat > "$change_theme" << 'EOF'
#!/bin/bash
# Change theme based on wallpaper using matugen

WALLPAPER="$1"

if [[ -z "$WALLPAPER" ]]; then
    echo "Usage: change-theme <wallpaper-path>"
    echo ""
    echo "Available wallpapers:"
    find ~/.config/wallpapers -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.webp" \) 2>/dev/null
    exit 1
fi

if [[ ! -f "$WALLPAPER" ]]; then
    # Try looking in wallpapers directory
    if [[ -f "$HOME/.config/wallpapers/$WALLPAPER" ]]; then
        WALLPAPER="$HOME/.config/wallpapers/$WALLPAPER"
    else
        echo "Error: Wallpaper not found: $WALLPAPER"
        exit 1
    fi
fi

echo "Generating theme from: $WALLPAPER"
matugen image "$WALLPAPER"

echo "Theme applied! Restart applications to see changes."
EOF
            chmod +x "$change_theme"
            success "Created change-theme helper"
        fi
    else
        success "change-theme helper exists"
    fi
}

# -----------------------------------------------------
# Cleanup
# -----------------------------------------------------

cleanup() {
    section "Cleanup"
    
    if [[ "$DRY_RUN" == true ]]; then
        log "Would clean up temporary files"
        return 0
    fi
    
    # Clean pacman cache (keep last 2 versions)
    if has_command paccache; then
        log "Cleaning package cache..."
        sudo paccache -r -k 2 2>/dev/null || true
        success "Package cache cleaned"
    fi
    
    # Clean yay cache
    if has_command yay; then
        yay -Sc --noconfirm 2>/dev/null || true
    fi
}

# -----------------------------------------------------
# Show Next Steps
# -----------------------------------------------------

show_next_steps() {
    section "Manual Steps Required"
    
    echo "The following require manual configuration:"
    echo ""
    echo "  ${BOLD}SSH Keys${NC}"
    echo "    - Restore keys to ~/.ssh/"
    echo "    - Set permissions: chmod 700 ~/.ssh && chmod 600 ~/.ssh/*"
    echo ""
    echo "  ${BOLD}GPG Keys${NC}"
    echo "    - Import: gpg --import private-key.asc"
    echo ""
    echo "  ${BOLD}Browser${NC}"
    echo "    - Log in to sync bookmarks and passwords"
    echo ""
    echo "  ${BOLD}Application Logins${NC}"
    echo "    - Slack, Discord, Spotify, etc."
    echo ""
    
    # Create docs directory and manual steps file
    local docs_dir="$(get_zera_dir)/docs"
    ensure_dir "$docs_dir"
    
    if [[ ! -f "$docs_dir/MANUAL_STEPS.md" ]] && [[ "$DRY_RUN" != true ]]; then
        cat > "$docs_dir/MANUAL_STEPS.md" << 'EOF'
# Manual Steps

These steps require manual intervention after installation.

## SSH Keys
- Restore keys to `~/.ssh/`
- Set permissions: `chmod 700 ~/.ssh && chmod 600 ~/.ssh/*`
- Add to agent: `ssh-add ~/.ssh/id_ed25519`
- Test: `ssh -T git@github.com`

## GPG Keys
- Import: `gpg --import private-key.asc`
- Trust: `gpg --edit-key <key-id>` then `trust`

## Browser
- Log in to sync service to restore bookmarks/passwords
- Apply matugen theme if desired

## Applications
- Slack, Discord, Spotify, VS Code/Cursor - log in to each
- 1Password or other password manager

## Bluetooth
- Re-pair all Bluetooth devices (pairing doesn't persist)

## Theme
- Run `change-theme <wallpaper>` to set your color scheme
EOF
    fi
}

# -----------------------------------------------------
# Run Post-Install
# -----------------------------------------------------

apply_theme
create_helper_scripts
cleanup
show_next_steps

echo ""
success "Post-installation complete!"
