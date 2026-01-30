#!/bin/bash
# -----------------------------------------------------
# ZERA - Preflight Checks
# -----------------------------------------------------
# Verifies system requirements before installation
# This script is sourced by install.sh

# Ensure common functions are available
[[ -z "${ZERA_COMMON_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/../helpers/common.sh"

log "Running preflight checks..."

# -----------------------------------------------------
# Check: Arch Linux
# -----------------------------------------------------
check_arch_linux() {
    if is_arch; then
        success "Running on Arch Linux"
        return 0
    else
        error "Zera requires Arch Linux"
        echo "  This installer is designed specifically for Arch Linux."
        echo "  For other distributions, you may need to adapt the scripts."
        return 1
    fi
}

# -----------------------------------------------------
# Check: Not running as root
# -----------------------------------------------------
check_not_root() {
    if [[ $EUID -eq 0 ]]; then
        error "Do not run as root"
        echo "  Run this script as a normal user."
        echo "  Sudo will be used when needed."
        return 1
    else
        success "Running as user: $USER"
        return 0
    fi
}

# -----------------------------------------------------
# Check: Sudo access
# -----------------------------------------------------
check_sudo() {
    if sudo -v &>/dev/null; then
        success "Sudo access available"
        # Keep sudo alive in background
        while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
        return 0
    else
        error "Sudo access required"
        echo "  This script needs sudo privileges to install packages."
        return 1
    fi
}

# -----------------------------------------------------
# Check: Internet connection
# -----------------------------------------------------
check_internet() {
    log "Checking internet connection..."
    
    if ping -c 1 -W 5 archlinux.org &>/dev/null; then
        success "Internet connection available"
        return 0
    elif ping -c 1 -W 5 1.1.1.1 &>/dev/null; then
        success "Internet connection available (DNS might be slow)"
        return 0
    else
        error "No internet connection"
        echo "  Please connect to the internet and try again."
        return 1
    fi
}

# -----------------------------------------------------
# Check: Disk space
# -----------------------------------------------------
check_disk_space() {
    local required_mb=5000  # 5GB minimum
    local available_mb
    
    available_mb=$(df -m "$HOME" | awk 'NR==2 {print $4}')
    
    if [[ $available_mb -ge $required_mb ]]; then
        success "Disk space: ${available_mb}MB available (${required_mb}MB required)"
        return 0
    else
        error "Insufficient disk space"
        echo "  Available: ${available_mb}MB"
        echo "  Required: ${required_mb}MB"
        return 1
    fi
}

# -----------------------------------------------------
# Check: Base packages
# -----------------------------------------------------
check_base_packages() {
    local missing=()
    
    # Essential packages that should exist on any Arch install
    for pkg in bash coreutils; do
        if ! has_command "$pkg" && ! is_installed "$pkg"; then
            missing+=("$pkg")
        fi
    done
    
    if [[ ${#missing[@]} -eq 0 ]]; then
        success "Base system packages present"
        return 0
    else
        error "Missing base packages: ${missing[*]}"
        return 1
    fi
}

# -----------------------------------------------------
# Install: Bootstrap dependencies
# -----------------------------------------------------
install_bootstrap_deps() {
    section "Installing bootstrap dependencies"
    
    local deps=(git base-devel stow)
    local to_install=()
    
    for pkg in "${deps[@]}"; do
        if ! is_installed "$pkg"; then
            to_install+=("$pkg")
        else
            success "$pkg already installed"
        fi
    done
    
    if [[ ${#to_install[@]} -gt 0 ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            log "Would install: ${to_install[*]}"
        else
            log "Installing: ${to_install[*]}"
            sudo pacman -Syu --noconfirm --needed "${to_install[@]}"
            success "Bootstrap dependencies installed"
        fi
    fi
}

# -----------------------------------------------------
# Run All Checks
# -----------------------------------------------------

# Critical checks (fail immediately if these fail)
check_arch_linux || exit 1
check_not_root || exit 1
check_sudo || exit 1
check_internet || exit 1
check_disk_space || exit 1
check_base_packages || exit 1

# Install bootstrap dependencies
install_bootstrap_deps

echo ""
success "All preflight checks passed!"
