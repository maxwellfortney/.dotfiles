#!/bin/bash
# -----------------------------------------------------
# ZERA - Main Installer
# -----------------------------------------------------
# Orchestrates the complete installation process
# Can be run:
#   - Directly from git clone
#   - Via boot.sh (curl install)
#   - Via `zera install` (AUR package)
#
# Usage:
#   ./install.sh           # Interactive installation
#   ./install.sh --dry-run # Show what would be done

set -eEo pipefail
set +u  # Disable nounset (may be inherited from parent)

# -----------------------------------------------------
# Setup
# -----------------------------------------------------

# Determine script location (supports multiple install methods)
if [[ -n "${ZERA_DIR:-}" ]]; then
    # Already set by boot.sh or zera command
    :
elif [[ -d "/usr/share/zera" ]]; then
    # Installed as system package (AUR)
    export ZERA_DIR="/usr/share/zera"
else
    # Running directly from git clone
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    export ZERA_DIR="$SCRIPT_DIR"
fi

export ZERA_INSTALL="$ZERA_DIR/install"

# Parse command line arguments
DRY_RUN=false
SKIP_PROMPTS=false
PACKAGE_TIER="recommended"  # minimal, recommended, full

while [[ "${1:-}" =~ ^- ]]; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --skip-prompts)
            SKIP_PROMPTS=true
            shift
            ;;
        --minimal)
            PACKAGE_TIER="minimal"
            shift
            ;;
        --full)
            PACKAGE_TIER="full"
            shift
            ;;
        -h|--help)
            echo "Zera Installer"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --dry-run       Show what would be done without making changes"
            echo "  --skip-prompts  Use defaults, don't ask questions"
            echo "  --minimal       Install minimal package set"
            echo "  --full          Install full package set (includes optional)"
            echo "  -h, --help      Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

export DRY_RUN
export SKIP_PROMPTS
export PACKAGE_TIER

# -----------------------------------------------------
# Source Helper Functions
# -----------------------------------------------------

source "$ZERA_INSTALL/helpers/common.sh"

# -----------------------------------------------------
# Show Banner (if not already shown by boot.sh)
# -----------------------------------------------------

if [[ -z "${ZERA_BANNER_SHOWN:-}" ]]; then
    clear
    echo -e "${CYAN}"
    cat << 'EOF'

    ███████╗███████╗██████╗  █████╗ 
    ╚══███╔╝██╔════╝██╔══██╗██╔══██╗
      ███╔╝ █████╗  ██████╔╝███████║
     ███╔╝  ██╔══╝  ██╔══██╗██╔══██║
    ███████╗███████╗██║  ██║██║  ██║
    ╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝

EOF
    echo -e "${NC}"
    export ZERA_BANNER_SHOWN=1
fi

# Show version
ZERA_VERSION=$(cat "$ZERA_DIR/version" 2>/dev/null || echo "dev")
info "Zera v${ZERA_VERSION}"
echo ""

if [[ "$DRY_RUN" == true ]]; then
    warn "DRY RUN MODE - No changes will be made"
    echo ""
fi

# -----------------------------------------------------
# Installation Steps
# -----------------------------------------------------

# Track what was done for summary
declare -a COMPLETED_STEPS=()
declare -a FAILED_STEPS=()
declare -a SKIPPED_STEPS=()

run_step() {
    local step_name="$1"
    local step_script="$2"
    
    if [[ -f "$step_script" ]]; then
        if source "$step_script"; then
            COMPLETED_STEPS+=("$step_name")
        else
            FAILED_STEPS+=("$step_name")
        fi
    else
        warn "Step script not found: $step_script"
        SKIPPED_STEPS+=("$step_name")
    fi
}

# Step 1: Preflight Checks
step 1 "Preflight Checks"
run_step "Preflight checks" "$ZERA_INSTALL/preflight/checks.sh"

# Step 2: Interactive Prompts (unless skipped)
if [[ "$SKIP_PROMPTS" != true ]]; then
    step 2 "Configuration"
    run_step "User configuration" "$ZERA_INSTALL/interactive/prompts.sh"
else
    step 2 "Configuration (Skipped)"
    info "Using defaults (--skip-prompts)"
    SKIPPED_STEPS+=("User configuration")
fi

# Step 3: Install Packages
step 3 "Install Packages"
run_step "Core packages" "$ZERA_INSTALL/packages/core.sh"
run_step "AUR packages" "$ZERA_INSTALL/packages/aur.sh"
if [[ "$PACKAGE_TIER" == "full" ]]; then
    run_step "Optional packages" "$ZERA_INSTALL/packages/optional.sh"
fi

# Step 4: Stow Dotfiles
step 4 "Install Dotfiles"
run_step "Stow dotfiles" "$ZERA_INSTALL/dotfiles/stow.sh"

# Step 5: Enable Services
step 5 "Enable Services"
run_step "Systemd services" "$ZERA_INSTALL/services/enable.sh"

# Step 6: System Configuration
step 6 "System Configuration"
run_step "System settings" "$ZERA_INSTALL/system/configure.sh"

# Step 7: Post-Install
step 7 "Finishing Up"
run_step "Post-install tasks" "$ZERA_INSTALL/post-install/finish.sh"

# -----------------------------------------------------
# Summary
# -----------------------------------------------------

echo ""
if [[ ${#FAILED_STEPS[@]} -eq 0 ]]; then
    echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}${BOLD}  Installation Complete!${NC}"
    echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════════════${NC}"
else
    echo -e "${YELLOW}${BOLD}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}${BOLD}  Installation Completed with Warnings${NC}"
    echo -e "${YELLOW}${BOLD}═══════════════════════════════════════════════════════════${NC}"
fi
echo ""

if [[ ${#COMPLETED_STEPS[@]} -gt 0 ]]; then
    echo -e "${GREEN}Completed:${NC}"
    for item in "${COMPLETED_STEPS[@]}"; do
        echo -e "  ${GREEN}✓${NC} $item"
    done
    echo ""
fi

if [[ ${#FAILED_STEPS[@]} -gt 0 ]]; then
    echo -e "${RED}Failed:${NC}"
    for item in "${FAILED_STEPS[@]}"; do
        echo -e "  ${RED}✗${NC} $item"
    done
    echo ""
fi

if [[ ${#SKIPPED_STEPS[@]} -gt 0 ]]; then
    echo -e "${YELLOW}Skipped:${NC}"
    for item in "${SKIPPED_STEPS[@]}"; do
        echo -e "  ${YELLOW}○${NC} $item"
    done
    echo ""
fi

if [[ "$DRY_RUN" == true ]]; then
    echo "This was a dry run. Run without --dry-run to apply changes."
    echo ""
else
    echo "Next steps:"
    echo "  1. Log out and log back in (or reboot)"
    echo "  2. Hyprland will start automatically from SDDM"
    echo "  3. Run 'change-theme <wallpaper>' to set your theme"
    echo ""
    echo "For manual configuration steps, see:"
    echo "  $ZERA_DIR/docs/MANUAL_STEPS.md"
    echo ""
fi

# Exit with error if there were failures
if [[ ${#FAILED_STEPS[@]} -gt 0 ]]; then
    exit 1
fi
