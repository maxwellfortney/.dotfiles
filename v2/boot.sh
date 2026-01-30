#!/bin/bash
# -----------------------------------------------------
# ZERA - Bootstrap Script
# -----------------------------------------------------
# This is the curl target for one-liner installation:
#   curl -sL https://raw.githubusercontent.com/USER/zera/main/boot.sh | bash
#
# It installs git, clones the repo, and runs the installer.

set -eEo pipefail

# Define Zera locations
export ZERA_DIR="$HOME/.local/share/zera"
export ZERA_REPO="${ZERA_REPO:-maxwell/zera}"  # Override with your repo
export ZERA_BRANCH="${ZERA_BRANCH:-main}"

# ASCII Art Banner
show_banner() {
    clear
    echo -e "\033[0;36m"
    cat << 'EOF'

    ███████╗███████╗██████╗  █████╗ 
    ╚══███╔╝██╔════╝██╔══██╗██╔══██╗
      ███╔╝ █████╗  ██████╔╝███████║
     ███╔╝  ██╔══╝  ██╔══██╗██╔══██║
    ███████╗███████╗██║  ██║██║  ██║
    ╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝
                                    
    Arch Linux + Hyprland Installer

EOF
    echo -e "\033[0m"
}

# Check if we're on Arch Linux
check_arch() {
    if [[ ! -f /etc/arch-release ]]; then
        echo -e "\033[0;31m✗ Zera requires Arch Linux\033[0m"
        echo "  This installer is designed for Arch Linux only."
        exit 1
    fi
}

# Install git if not present
install_git() {
    if ! command -v git &>/dev/null; then
        echo -e "\033[0;34m[$(date '+%H:%M:%S')]\033[0m Installing git..."
        sudo pacman -Syu --noconfirm --needed git
        echo -e "\033[0;32m✓\033[0m Git installed"
    else
        echo -e "\033[0;32m✓\033[0m Git already installed"
    fi
}

# Clone or update the Zera repository
clone_repo() {
    echo -e "\033[0;34m[$(date '+%H:%M:%S')]\033[0m Setting up Zera..."
    
    if [[ -d "$ZERA_DIR" ]]; then
        echo "  Existing installation found, updating..."
        cd "$ZERA_DIR"
        git fetch origin "$ZERA_BRANCH"
        git checkout "$ZERA_BRANCH"
        git pull origin "$ZERA_BRANCH"
    else
        echo "  Cloning from: https://github.com/${ZERA_REPO}.git"
        git clone "https://github.com/${ZERA_REPO}.git" "$ZERA_DIR"
        cd "$ZERA_DIR"
        git checkout "$ZERA_BRANCH"
    fi
    
    echo -e "\033[0;32m✓\033[0m Zera repository ready"
    echo -e "\033[2m  Location: $ZERA_DIR\033[0m"
    echo -e "\033[2m  Branch: $ZERA_BRANCH\033[0m"
}

# Run the main installer
run_installer() {
    echo ""
    echo -e "\033[0;34m[$(date '+%H:%M:%S')]\033[0m Starting installation..."
    echo ""
    
    # Source the main installer
    source "$ZERA_DIR/install.sh"
}

# Main
main() {
    show_banner
    
    echo "Welcome to Zera!"
    echo "This will install a complete Arch Linux + Hyprland setup."
    echo ""
    
    check_arch
    install_git
    clone_repo
    run_installer
}

main "$@"
