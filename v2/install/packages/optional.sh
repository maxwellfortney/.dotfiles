#!/bin/bash
# -----------------------------------------------------
# ZERA - Optional Package Installation
# -----------------------------------------------------
# Installs optional packages based on user-selected features
# This script is sourced by install.sh

# Ensure common functions are available
[[ -z "${ZERA_COMMON_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/../helpers/common.sh"

log "Installing optional packages..."

# Features selected during prompts are in ZERA_FEATURES (comma-separated)

# -----------------------------------------------------
# Feature: Gaming
# -----------------------------------------------------

install_gaming() {
    section "Gaming Packages"
    
    local packages=(
        steam
        lutris
        gamemode
        lib32-gamemode
        mangohud
        lib32-mangohud
    )
    
    if [[ "$DRY_RUN" == true ]]; then
        log "Would install gaming packages: ${packages[*]}"
        return 0
    fi
    
    # Enable multilib repository if not already
    if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
        log "Enabling multilib repository..."
        sudo bash -c 'echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf'
        sudo pacman -Sy
    fi
    
    install_packages "${packages[@]}"
    success "Gaming packages installed"
}

# -----------------------------------------------------
# Feature: Development
# -----------------------------------------------------

install_development() {
    section "Development Packages"
    
    local packages=(
        docker
        docker-compose
        docker-buildx
    )
    
    if [[ "$DRY_RUN" == true ]]; then
        log "Would install development packages: ${packages[*]}"
        return 0
    fi
    
    install_packages "${packages[@]}"
    
    # Add user to docker group
    if ! groups "$USER" | grep -q docker; then
        log "Adding $USER to docker group..."
        sudo usermod -aG docker "$USER"
        info "Log out and back in for docker group to take effect"
    fi
    
    success "Development packages installed"
}

# -----------------------------------------------------
# Feature: Multimedia
# -----------------------------------------------------

install_multimedia() {
    section "Multimedia Packages"
    
    local packages=(
        obs-studio
        gimp
        inkscape
        audacity
        kdenlive
    )
    
    if [[ "$DRY_RUN" == true ]]; then
        log "Would install multimedia packages: ${packages[*]}"
        return 0
    fi
    
    install_packages "${packages[@]}"
    success "Multimedia packages installed"
}

# -----------------------------------------------------
# Feature: Office
# -----------------------------------------------------

install_office() {
    section "Office Packages"
    
    local packages=(
        libreoffice-fresh
    )
    
    if [[ "$DRY_RUN" == true ]]; then
        log "Would install office packages: ${packages[*]}"
        return 0
    fi
    
    install_packages "${packages[@]}"
    success "Office packages installed"
}

# -----------------------------------------------------
# Install Based on Selected Features
# -----------------------------------------------------

install_selected_features() {
    if [[ -z "$ZERA_FEATURES" ]]; then
        info "No optional features selected"
        return 0
    fi
    
    log "Installing selected features: $ZERA_FEATURES"
    
    IFS=',' read -ra features <<< "$ZERA_FEATURES"
    
    for feature in "${features[@]}"; do
        case "$feature" in
            gaming)
                install_gaming
                ;;
            development)
                install_development
                ;;
            multimedia)
                install_multimedia
                ;;
            office)
                install_office
                ;;
            *)
                warn "Unknown feature: $feature"
                ;;
        esac
    done
}

# -----------------------------------------------------
# Run Installation
# -----------------------------------------------------

install_selected_features

echo ""
success "Optional packages complete!"
