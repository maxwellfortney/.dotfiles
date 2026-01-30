#!/bin/bash
# -----------------------------------------------------
# ZERA - AUR Package Installation
# -----------------------------------------------------
# Installs yay and AUR packages
# This script is sourced by install.sh

# Ensure common functions are available
[[ -z "${ZERA_COMMON_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/../helpers/common.sh"

log "Setting up AUR packages..."

DEFAULTS_DIR="$(get_defaults_dir)"

# -----------------------------------------------------
# Install yay (AUR Helper)
# -----------------------------------------------------

install_yay() {
    section "AUR Helper"
    
    if has_command yay; then
        success "yay already installed"
        return 0
    fi
    
    if has_command paru; then
        success "paru already installed (using as AUR helper)"
        return 0
    fi
    
    if [[ "$DRY_RUN" == true ]]; then
        log "Would install yay from AUR"
        return 0
    fi
    
    log "Installing yay..."
    
    # Create temp directory
    local tmpdir
    tmpdir=$(mktemp -d)
    
    # Clone and build yay
    cd "$tmpdir" || return 1
    git clone https://aur.archlinux.org/yay.git
    cd yay || return 1
    
    makepkg -si --noconfirm
    
    # Cleanup
    cd ~ || true
    rm -rf "$tmpdir"
    
    if has_command yay; then
        success "yay installed successfully"
    else
        error "Failed to install yay"
        return 1
    fi
}

# -----------------------------------------------------
# Install AUR Packages
# -----------------------------------------------------

install_aur_packages() {
    section "AUR Packages"
    
    local helper
    helper=$(get_aur_helper)
    
    if [[ -z "$helper" ]]; then
        error "No AUR helper available"
        return 1
    fi
    
    # Read AUR package list
    local packages=()
    local aur_file="$DEFAULTS_DIR/packages-aur.txt"
    
    if [[ -f "$aur_file" ]]; then
        while IFS= read -r line; do
            [[ -z "$line" || "$line" =~ ^# ]] && continue
            packages+=("$line")
        done < "$aur_file"
    fi
    
    if [[ ${#packages[@]} -eq 0 ]]; then
        info "No AUR packages defined"
        return 0
    fi
    
    # Filter already installed
    local to_install=()
    for pkg in "${packages[@]}"; do
        if ! is_installed "$pkg"; then
            to_install+=("$pkg")
        else
            success "$pkg already installed"
        fi
    done
    
    if [[ ${#to_install[@]} -eq 0 ]]; then
        success "All AUR packages already installed"
        return 0
    fi
    
    if [[ "$DRY_RUN" == true ]]; then
        log "Would install ${#to_install[@]} AUR packages:"
        printf '  %s\n' "${to_install[@]}"
        return 0
    fi
    
    # Install one by one to handle failures gracefully
    local failed=()
    local succeeded=0
    
    for pkg in "${to_install[@]}"; do
        log "Installing AUR package: $pkg"
        if $helper -S --noconfirm --needed "$pkg" 2>&1; then
            success "Installed $pkg"
            ((succeeded++)) || true
        else
            warn "Failed to install: $pkg"
            failed+=("$pkg")
        fi
    done
    
    if [[ ${#failed[@]} -eq 0 ]]; then
        success "All AUR packages installed ($succeeded total)"
    else
        warn "Installed $succeeded packages, ${#failed[@]} failed"
        echo "  Failed: ${failed[*]}"
    fi
}

# -----------------------------------------------------
# Run Installation
# -----------------------------------------------------

install_yay
install_aur_packages

echo ""
success "AUR setup complete!"
