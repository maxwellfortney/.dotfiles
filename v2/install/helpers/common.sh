#!/bin/bash
# -----------------------------------------------------
# ZERA - Common Helper Functions
# -----------------------------------------------------
# Shared functions used across all install scripts
# This file is sourced by other scripts, not run directly

# Prevent multiple sourcing
[[ -n "${ZERA_COMMON_LOADED:-}" ]] && return
ZERA_COMMON_LOADED=1

# -----------------------------------------------------
# Colors
# -----------------------------------------------------
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export CYAN='\033[0;36m'
export MAGENTA='\033[0;35m'
export BOLD='\033[1m'
export DIM='\033[2m'
export NC='\033[0m'  # No Color

# -----------------------------------------------------
# Logging Functions
# -----------------------------------------------------

# Log with timestamp
log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"
}

# Success message with checkmark
success() {
    echo -e "${GREEN}✓${NC} $1"
}

# Warning message
warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Error message
error() {
    echo -e "${RED}✗${NC} $1"
}

# Info message (dimmed)
info() {
    echo -e "${DIM}$1${NC}"
}

# Step header (for major sections)
step() {
    local step_num="$1"
    local step_name="$2"
    echo ""
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}${BOLD}  Step $step_num: $step_name${NC}"
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Section header (for subsections)
section() {
    echo ""
    echo -e "${MAGENTA}▸ $1${NC}"
    echo ""
}

# -----------------------------------------------------
# System Detection
# -----------------------------------------------------

# Check if running on Arch Linux
is_arch() {
    [[ -f /etc/arch-release ]]
}

# Check if command exists
has_command() {
    command -v "$1" &>/dev/null
}

# Get hostname reliably
get_hostname() {
    if has_command hostname; then
        hostname
    elif [[ -f /etc/hostname ]]; then
        cat /etc/hostname | tr -d '[:space:]'
    elif has_command hostnamectl; then
        hostnamectl --static 2>/dev/null || echo "zera"
    else
        echo "zera"
    fi
}

# -----------------------------------------------------
# Package Management
# -----------------------------------------------------

# Check if a pacman package is installed
is_installed() {
    pacman -Qi "$1" &>/dev/null
}

# Install package if not already installed
install_if_missing() {
    local pkg="$1"
    if is_installed "$pkg"; then
        success "$pkg already installed"
        return 0
    else
        log "Installing $pkg..."
        if sudo pacman -S --noconfirm --needed "$pkg"; then
            success "Installed $pkg"
            return 0
        else
            error "Failed to install $pkg"
            return 1
        fi
    fi
}

# Install multiple packages at once
install_packages() {
    local packages=("$@")
    local to_install=()
    
    # Filter to only packages not already installed
    for pkg in "${packages[@]}"; do
        if ! is_installed "$pkg"; then
            to_install+=("$pkg")
        fi
    done
    
    if [[ ${#to_install[@]} -eq 0 ]]; then
        success "All packages already installed"
        return 0
    fi
    
    log "Installing ${#to_install[@]} packages..."
    if sudo pacman -S --noconfirm --needed "${to_install[@]}"; then
        success "Installed ${#to_install[@]} packages"
        return 0
    else
        error "Some packages failed to install"
        return 1
    fi
}

# Get AUR helper (yay or paru)
get_aur_helper() {
    if has_command yay; then
        echo "yay"
    elif has_command paru; then
        echo "paru"
    else
        echo ""
    fi
}

# Install AUR package
install_aur() {
    local pkg="$1"
    local helper
    helper=$(get_aur_helper)
    
    if [[ -z "$helper" ]]; then
        error "No AUR helper found"
        return 1
    fi
    
    if is_installed "$pkg"; then
        success "$pkg already installed"
        return 0
    fi
    
    log "Installing $pkg from AUR..."
    if $helper -S --noconfirm --needed "$pkg"; then
        success "Installed $pkg"
        return 0
    else
        error "Failed to install $pkg"
        return 1
    fi
}

# -----------------------------------------------------
# User Interaction
# -----------------------------------------------------

# Prompt for yes/no with default
confirm() {
    local prompt="$1"
    local default="${2:-y}"
    local yn
    
    if [[ "$default" == "y" ]]; then
        read -rp "$prompt [Y/n] " yn
        yn="${yn:-y}"
    else
        read -rp "$prompt [y/N] " yn
        yn="${yn:-n}"
    fi
    
    [[ "$yn" =~ ^[Yy] ]]
}

# Prompt for text input with default
prompt_text() {
    local prompt="$1"
    local default="$2"
    local result
    
    if [[ -n "$default" ]]; then
        read -rp "$prompt [$default]: " result
        echo "${result:-$default}"
    else
        read -rp "$prompt: " result
        echo "$result"
    fi
}

# Select from options using fzf if available, fallback to numbered list
select_option() {
    local prompt="$1"
    shift
    local options=("$@")
    
    echo -e "${CYAN}$prompt${NC}"
    
    if has_command fzf; then
        printf '%s\n' "${options[@]}" | fzf --height=10 --layout=reverse --prompt="> "
    else
        # Fallback to numbered selection
        local i=1
        for opt in "${options[@]}"; do
            echo "  $i) $opt"
            ((i++))
        done
        
        local choice
        read -rp "Enter number: " choice
        
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#options[@]} )); then
            echo "${options[$((choice-1))]}"
        else
            echo "${options[0]}"  # Default to first option
        fi
    fi
}

# Multi-select using fzf if available
select_multiple() {
    local prompt="$1"
    shift
    local options=("$@")
    
    echo -e "${CYAN}$prompt${NC}"
    
    if has_command fzf; then
        printf '%s\n' "${options[@]}" | fzf --multi --height=15 --layout=reverse --prompt="> "
    else
        # Fallback: show options and ask for comma-separated numbers
        local i=1
        for opt in "${options[@]}"; do
            echo "  $i) $opt"
            ((i++))
        done
        
        local choices
        read -rp "Enter numbers (comma-separated): " choices
        
        IFS=',' read -ra selected <<< "$choices"
        for idx in "${selected[@]}"; do
            idx=$(echo "$idx" | tr -d ' ')
            if [[ "$idx" =~ ^[0-9]+$ ]] && (( idx >= 1 && idx <= ${#options[@]} )); then
                echo "${options[$((idx-1))]}"
            fi
        done
    fi
}

# -----------------------------------------------------
# File Operations
# -----------------------------------------------------

# Create directory if it doesn't exist
ensure_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
    fi
}

# Backup a file before modifying
backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        cp "$file" "${file}.backup.$(date +%Y%m%d_%H%M%S)"
    fi
}

# -----------------------------------------------------
# Path Resolution
# -----------------------------------------------------

# Get the directory where Zera is installed
get_zera_dir() {
    if [[ -n "$ZERA_DIR" ]]; then
        echo "$ZERA_DIR"
    else
        # Try to find it relative to this script
        local script_dir
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        # Go up from install/helpers to root
        echo "$(dirname "$(dirname "$script_dir")")"
    fi
}

# Get the config directory (where stow packages live)
get_config_dir() {
    echo "$(get_zera_dir)/config"
}

# Get the defaults directory (package lists)
get_defaults_dir() {
    echo "$(get_zera_dir)/defaults"
}
