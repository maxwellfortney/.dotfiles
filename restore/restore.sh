#!/bin/bash
# -----------------------------------------------------
# MAIN RESTORATION SCRIPT
# -----------------------------------------------------
# Orchestrates the complete system restoration process
# Run this script on a fresh Arch Linux installation to
# restore your complete system state.
#
# Usage:
#   ./restore/restore.sh           # Full restoration
#   ./restore/restore.sh --dry-run # Show what would be done
#   ./restore/restore.sh --skip-packages # Skip package installation

# Don't exit on error - we want to continue and show summary
# set -e

# Track failures for summary
declare -a FAILURES=()
declare -a WARNINGS=()
declare -a SUCCESSES=()

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# Parse arguments
DRY_RUN=false
SKIP_PACKAGES=false
SKIP_SERVICES=false
SKIP_SYSTEM=false
SKIP_DOTFILES=false

while [[ "$1" =~ ^- ]]; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --skip-packages)
            SKIP_PACKAGES=true
            shift
            ;;
        --skip-services)
            SKIP_SERVICES=true
            shift
            ;;
        --skip-system)
            SKIP_SYSTEM=true
            shift
            ;;
        --skip-dotfiles)
            SKIP_DOTFILES=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --dry-run        Show what would be done without making changes"
            echo "  --skip-packages  Skip package installation"
            echo "  --skip-services  Skip service enabling"
            echo "  --skip-system    Skip system configuration"
            echo "  --skip-dotfiles  Skip dotfiles stowing"
            echo "  -h, --help       Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

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

step() {
    echo ""
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}${BOLD}  Step $1: $2${NC}"
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# -----------------------------------------------------
# Pre-flight Checks
# -----------------------------------------------------
preflight_checks() {
    step "0" "Pre-flight Checks"
    
    # Check if we're on Arch Linux
    if [ -f /etc/arch-release ]; then
        success "Running on Arch Linux"
    else
        warn "Not running on Arch Linux - some features may not work"
    fi
    
    # Check sudo access
    if sudo -v &>/dev/null; then
        success "Sudo access available"
    else
        error "Sudo access required but not available"
        exit 1
    fi
    
    # Check required tools
    local missing=()
    
    if ! command -v stow &> /dev/null; then
        missing+=("stow")
    fi
    
    if ! command -v git &> /dev/null; then
        missing+=("git")
    fi
    
    if [ ${#missing[@]} -gt 0 ]; then
        warn "Missing required tools: ${missing[*]}"
        echo "Run ./scripts/install-deps.sh first to install dependencies"
        exit 1
    fi
    
    success "All required tools installed"
    
    # Check state files exist
    if [ ! -d "$DOTFILES_DIR/state" ] || [ ! -f "$DOTFILES_DIR/state/packages-pacman.txt" ]; then
        warn "State files not found - was capture-state.sh run?"
        echo "Some restoration steps may be skipped"
    else
        success "State files found"
    fi
    
    if [ "$DRY_RUN" = true ]; then
        echo ""
        warn "DRY RUN MODE - No changes will be made"
    fi
}

# -----------------------------------------------------
# Run Restoration Steps
# -----------------------------------------------------
run_restore() {
    local step_num=1
    
    # Step 1: Install Packages
    if [ "$SKIP_PACKAGES" = true ]; then
        step "$step_num" "Packages (SKIPPED)"
        warn "Package installation skipped (--skip-packages)"
    else
        step "$step_num" "Install Packages"
        if [ "$DRY_RUN" = true ]; then
            log "Would run: restore-packages.sh"
            local pacman_count aur_count
            pacman_count=$(wc -l < "$DOTFILES_DIR/state/packages-pacman.txt" 2>/dev/null || echo 0)
            aur_count=$(wc -l < "$DOTFILES_DIR/state/packages-aur.txt" 2>/dev/null || echo 0)
            log "  - $pacman_count pacman packages"
            log "  - $aur_count AUR packages"
        else
            if "$SCRIPT_DIR/restore-packages.sh"; then
                SUCCESSES+=("Packages installed")
            else
                FAILURES+=("Some packages failed to install")
                warn "Package installation had errors, continuing..."
            fi
        fi
    fi
    ((step_num++)) || true
    
    # Step 2: Enable Services
    if [ "$SKIP_SERVICES" = true ]; then
        step "$step_num" "Services (SKIPPED)"
        warn "Service enabling skipped (--skip-services)"
    else
        step "$step_num" "Enable Services"
        if [ "$DRY_RUN" = true ]; then
            log "Would run: restore-services.sh"
            local service_count user_service_count
            service_count=$(wc -l < "$DOTFILES_DIR/state/services-enabled.txt" 2>/dev/null || echo 0)
            user_service_count=$(wc -l < "$DOTFILES_DIR/state/services-user.txt" 2>/dev/null || echo 0)
            log "  - $service_count system services"
            log "  - $user_service_count user services"
        else
            if "$SCRIPT_DIR/restore-services.sh"; then
                SUCCESSES+=("Services enabled")
            else
                FAILURES+=("Some services failed to enable")
                warn "Service enabling had errors, continuing..."
            fi
        fi
    fi
    ((step_num++)) || true
    
    # Step 3: System Configuration
    if [ "$SKIP_SYSTEM" = true ]; then
        step "$step_num" "System Configuration (SKIPPED)"
        warn "System configuration skipped (--skip-system)"
    else
        step "$step_num" "System Configuration"
        if [ "$DRY_RUN" = true ]; then
            log "Would run: restore-system.sh"
            log "  - mkinitcpio.conf"
            log "  - sysctl settings"
            log "  - hostname, locale, timezone"
            log "  - user groups"
        else
            if "$SCRIPT_DIR/restore-system.sh"; then
                SUCCESSES+=("System configuration applied")
            else
                FAILURES+=("Some system configuration failed")
                warn "System configuration had errors, continuing..."
            fi
        fi
    fi
    ((step_num++)) || true
    
    # Step 4: Stow Dotfiles
    if [ "$SKIP_DOTFILES" = true ]; then
        step "$step_num" "Dotfiles (SKIPPED)"
        warn "Dotfiles stowing skipped (--skip-dotfiles)"
    else
        step "$step_num" "Stow Dotfiles"
        if [ "$DRY_RUN" = true ]; then
            log "Would run: restore-dotfiles.sh"
            local pkg_count
            pkg_count=$(find "$DOTFILES_DIR" -maxdepth 1 -type d ! -name '.' ! -name '.git' ! -name 'restore' ! -name 'scripts' ! -name 'state' ! -name 'logs' | wc -l)
            log "  - $pkg_count stow packages"
        else
            if "$SCRIPT_DIR/restore-dotfiles.sh"; then
                SUCCESSES+=("Dotfiles stowed")
            else
                FAILURES+=("Some dotfiles failed to stow")
                warn "Dotfiles stowing had errors, continuing..."
            fi
        fi
    fi
    ((step_num++)) || true
    
    # Step 5: Manual Steps
    step "$step_num" "Manual Steps Required"
    
    echo "The following steps require manual intervention:"
    echo ""
    
    if [ -f "$SCRIPT_DIR/restore-manual.md" ]; then
        # Print a summary of manual steps
        grep "^- \[" "$SCRIPT_DIR/restore-manual.md" 2>/dev/null | head -20 || true
    fi
    
    echo ""
    echo "See the full checklist at:"
    echo "  $SCRIPT_DIR/restore-manual.md"
}

# -----------------------------------------------------
# Summary
# -----------------------------------------------------
print_summary() {
    echo ""
    
    # Determine overall status
    if [ ${#FAILURES[@]} -eq 0 ]; then
        echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}${BOLD}  Restoration Complete!${NC}"
        echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════════════${NC}"
    else
        echo -e "${YELLOW}${BOLD}═══════════════════════════════════════════════════════════${NC}"
        echo -e "${YELLOW}${BOLD}  Restoration Completed with Errors${NC}"
        echo -e "${YELLOW}${BOLD}═══════════════════════════════════════════════════════════${NC}"
    fi
    echo ""
    
    if [ "$DRY_RUN" = true ]; then
        echo "This was a dry run. No changes were made."
        echo "Run without --dry-run to perform the actual restoration."
        echo ""
        return
    fi
    
    # Show successes
    if [ ${#SUCCESSES[@]} -gt 0 ]; then
        echo -e "${GREEN}Successes:${NC}"
        for item in "${SUCCESSES[@]}"; do
            echo -e "  ${GREEN}✓${NC} $item"
        done
        echo ""
    fi
    
    # Show failures
    if [ ${#FAILURES[@]} -gt 0 ]; then
        echo -e "${RED}Failures:${NC}"
        for item in "${FAILURES[@]}"; do
            echo -e "  ${RED}✗${NC} $item"
        done
        echo ""
        echo -e "${YELLOW}Review the output above for details on what failed.${NC}"
        echo -e "${YELLOW}You may need to manually fix these issues.${NC}"
        echo ""
    fi
    
    echo "Your system has been restored from the dotfiles state."
    echo ""
    echo "Next steps:"
    echo "  1. Review any warnings/failures above"
    echo "  2. Complete manual steps in restore/restore-manual.md"
    echo "  3. Reboot to apply all changes"
    echo ""
    echo "To set up automatic state sync:"
    echo "  ./scripts/setup-auto-sync.sh"
    echo ""
    
    # Exit with error code if there were failures
    if [ ${#FAILURES[@]} -gt 0 ]; then
        return 1
    fi
}

# -----------------------------------------------------
# Main
# -----------------------------------------------------
main() {
    echo ""
    echo -e "${BLUE}${BOLD}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}${BOLD}  Dotfiles System Restoration${NC}"
    echo -e "${BLUE}${BOLD}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "This script will restore your system from the dotfiles state."
    echo "Dotfiles directory: $DOTFILES_DIR"
    echo ""
    
    preflight_checks
    run_restore
    print_summary
}

main "$@"
