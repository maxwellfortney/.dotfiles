#!/bin/bash
# -----------------------------------------------------
# ZERA - Core Package Installation
# -----------------------------------------------------
# Installs essential packages for Hyprland
# This script is sourced by install.sh

# Ensure common functions are available
[[ -z "${ZERA_COMMON_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/../helpers/common.sh"

log "Installing core packages..."

# -----------------------------------------------------
# Read Package Lists
# -----------------------------------------------------

DEFAULTS_DIR="$(get_defaults_dir)"

# Read packages from file, filtering comments and empty lines
read_package_list() {
    local file="$1"
    local packages=()
    
    if [[ ! -f "$file" ]]; then
        warn "Package list not found: $file"
        return
    fi
    
    while IFS= read -r line; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^# ]] && continue
        packages+=("$line")
    done < "$file"
    
    printf '%s\n' "${packages[@]}"
}

# -----------------------------------------------------
# Detect CPU and GPU
# -----------------------------------------------------

detect_microcode() {
    if grep -q "AMD" /proc/cpuinfo 2>/dev/null; then
        echo "amd-ucode"
    elif grep -q "Intel" /proc/cpuinfo 2>/dev/null; then
        echo "intel-ucode"
    fi
}

detect_gpu_packages() {
    local gpu_packages=()
    
    # Check for NVIDIA
    if lspci 2>/dev/null | grep -qi nvidia; then
        log "NVIDIA GPU detected"
        gpu_packages+=(nvidia-open-dkms libva-nvidia-driver)
    fi
    
    # Check for AMD
    if lspci 2>/dev/null | grep -qi "amd.*radeon\|radeon.*amd\|amd.*vga"; then
        log "AMD GPU detected"
        gpu_packages+=(mesa vulkan-radeon libva-mesa-driver)
    fi
    
    # Check for Intel integrated
    if lspci 2>/dev/null | grep -qi "intel.*vga\|intel.*graphics"; then
        log "Intel GPU detected"
        gpu_packages+=(mesa vulkan-intel intel-media-driver)
    fi
    
    printf '%s\n' "${gpu_packages[@]}"
}

# -----------------------------------------------------
# Install Core Packages
# -----------------------------------------------------

install_core_packages() {
    section "Core System Packages"
    
    # Read core package list
    mapfile -t core_packages < <(read_package_list "$DEFAULTS_DIR/packages-core.txt")
    
    # Add microcode
    local microcode
    microcode=$(detect_microcode)
    if [[ -n "$microcode" ]]; then
        log "Adding CPU microcode: $microcode"
        core_packages+=("$microcode")
    fi
    
    # Add GPU packages
    mapfile -t gpu_packages < <(detect_gpu_packages)
    if [[ ${#gpu_packages[@]} -gt 0 ]]; then
        log "Adding GPU packages: ${gpu_packages[*]}"
        core_packages+=("${gpu_packages[@]}")
    fi
    
    if [[ "$DRY_RUN" == true ]]; then
        log "Would install ${#core_packages[@]} core packages:"
        printf '  %s\n' "${core_packages[@]}" | head -20
        if [[ ${#core_packages[@]} -gt 20 ]]; then
            echo "  ... and $((${#core_packages[@]} - 20)) more"
        fi
        return 0
    fi
    
    # Update package database
    log "Updating package database..."
    sudo pacman -Syu --noconfirm
    
    # Install packages
    log "Installing ${#core_packages[@]} packages..."
    if sudo pacman -S --noconfirm --needed "${core_packages[@]}"; then
        success "Core packages installed"
    else
        error "Some packages failed to install"
        return 1
    fi
}

# -----------------------------------------------------
# Install Recommended Packages
# -----------------------------------------------------

install_recommended_packages() {
    if [[ "$PACKAGE_TIER" == "minimal" ]]; then
        info "Skipping recommended packages (minimal tier selected)"
        return 0
    fi
    
    section "Recommended Packages"
    
    mapfile -t recommended_packages < <(read_package_list "$DEFAULTS_DIR/packages-recommended.txt")
    
    if [[ ${#recommended_packages[@]} -eq 0 ]]; then
        info "No recommended packages defined"
        return 0
    fi
    
    if [[ "$DRY_RUN" == true ]]; then
        log "Would install ${#recommended_packages[@]} recommended packages:"
        printf '  %s\n' "${recommended_packages[@]}"
        return 0
    fi
    
    log "Installing ${#recommended_packages[@]} recommended packages..."
    if sudo pacman -S --noconfirm --needed "${recommended_packages[@]}"; then
        success "Recommended packages installed"
    else
        warn "Some recommended packages failed to install"
    fi
}

# -----------------------------------------------------
# Install Shell-specific Packages
# -----------------------------------------------------

install_shell_packages() {
    section "Shell Configuration"
    
    local shell="${ZERA_SHELL:-fish}"
    
    case "$shell" in
        fish)
            install_if_missing fish
            install_if_missing starship
            ;;
        zsh)
            install_if_missing zsh
            install_if_missing starship
            # Could add zsh plugins here
            ;;
        bash)
            install_if_missing starship
            ;;
    esac
    
    success "Shell packages ready: $shell"
}

# -----------------------------------------------------
# Run Installation
# -----------------------------------------------------

install_core_packages
install_recommended_packages
install_shell_packages

echo ""
success "Package installation complete!"
