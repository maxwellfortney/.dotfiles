#!/bin/bash
# -----------------------------------------------------
# ZERA - Interactive Prompts
# -----------------------------------------------------
# Gathers user preferences for customization
# This script is sourced by install.sh

# Ensure common functions are available
[[ -z "${ZERA_COMMON_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/../helpers/common.sh"

log "Gathering configuration preferences..."
echo ""

# Store user choices in environment variables for other scripts
# These are exported so they persist across sourced scripts

# -----------------------------------------------------
# Hostname Configuration
# -----------------------------------------------------
configure_hostname() {
    section "Hostname"
    
    local current_hostname
    current_hostname=$(get_hostname)
    
    echo "Your hostname identifies this machine on the network."
    echo ""
    
    if [[ "$DRY_RUN" == true ]]; then
        log "Would prompt for hostname (current: $current_hostname)"
        export ZERA_HOSTNAME="$current_hostname"
        return
    fi
    
    ZERA_HOSTNAME=$(prompt_text "Enter hostname" "$current_hostname")
    export ZERA_HOSTNAME
    
    success "Hostname: $ZERA_HOSTNAME"
}

# -----------------------------------------------------
# Package Tier Selection
# -----------------------------------------------------
configure_packages() {
    section "Package Selection"
    
    echo "Choose how many packages to install:"
    echo ""
    echo "  ${BOLD}minimal${NC}     - Just Hyprland and essential tools"
    echo "  ${BOLD}recommended${NC} - Minimal + common apps (browser, editor, etc.)"
    echo "  ${BOLD}full${NC}        - Recommended + optional extras"
    echo ""
    
    if [[ "$DRY_RUN" == true ]]; then
        log "Would prompt for package tier (default: $PACKAGE_TIER)"
        return
    fi
    
    local options=("minimal" "recommended" "full")
    
    if has_command fzf; then
        PACKAGE_TIER=$(printf '%s\n' "${options[@]}" | fzf --height=5 --layout=reverse --prompt="Package tier> " --header="Select package tier")
    else
        local choice
        echo "  1) minimal"
        echo "  2) recommended"
        echo "  3) full"
        read -rp "Select [1-3, default=2]: " choice
        
        case "$choice" in
            1) PACKAGE_TIER="minimal" ;;
            3) PACKAGE_TIER="full" ;;
            *) PACKAGE_TIER="recommended" ;;
        esac
    fi
    
    export PACKAGE_TIER
    success "Package tier: $PACKAGE_TIER"
}

# -----------------------------------------------------
# Optional Features
# -----------------------------------------------------
configure_features() {
    section "Optional Features"
    
    echo "Select additional features to enable:"
    echo ""
    
    if [[ "$DRY_RUN" == true ]]; then
        log "Would prompt for optional features"
        export ZERA_FEATURES=""
        return
    fi
    
    local features=(
        "gaming:Gaming support (Steam, Lutris, gamemode)"
        "development:Development tools (Docker, various languages)"
        "multimedia:Multimedia creation (OBS, GIMP, etc.)"
        "office:Office suite (LibreOffice)"
    )
    
    local selected=()
    
    if has_command fzf; then
        # Use fzf multi-select
        while IFS= read -r line; do
            [[ -n "$line" ]] && selected+=("${line%%:*}")
        done < <(printf '%s\n' "${features[@]}" | fzf --multi --height=10 --layout=reverse --prompt="Features> " --header="Select features (Tab to multi-select, Enter to confirm)")
    else
        # Fallback to simple yes/no for each
        for feature in "${features[@]}"; do
            local key="${feature%%:*}"
            local desc="${feature#*:}"
            if confirm "  Include $desc?"; then
                selected+=("$key")
            fi
        done
    fi
    
    ZERA_FEATURES=$(IFS=,; echo "${selected[*]}")
    export ZERA_FEATURES
    
    if [[ -n "$ZERA_FEATURES" ]]; then
        success "Features: $ZERA_FEATURES"
    else
        info "No optional features selected"
    fi
}

# -----------------------------------------------------
# Shell Preference
# -----------------------------------------------------
configure_shell() {
    section "Default Shell"
    
    echo "Select your preferred shell:"
    echo ""
    
    if [[ "$DRY_RUN" == true ]]; then
        log "Would prompt for shell preference"
        export ZERA_SHELL="fish"
        return
    fi
    
    local options=("fish" "zsh" "bash")
    
    if has_command fzf; then
        ZERA_SHELL=$(printf '%s\n' "${options[@]}" | fzf --height=5 --layout=reverse --prompt="Shell> ")
    else
        echo "  1) fish (recommended)"
        echo "  2) zsh"
        echo "  3) bash"
        local choice
        read -rp "Select [1-3, default=1]: " choice
        
        case "$choice" in
            2) ZERA_SHELL="zsh" ;;
            3) ZERA_SHELL="bash" ;;
            *) ZERA_SHELL="fish" ;;
        esac
    fi
    
    export ZERA_SHELL
    success "Shell: $ZERA_SHELL"
}

# -----------------------------------------------------
# Confirmation
# -----------------------------------------------------
confirm_choices() {
    section "Confirm Configuration"
    
    echo "Installation will proceed with:"
    echo ""
    echo "  Hostname:      ${BOLD}${ZERA_HOSTNAME:-$(get_hostname)}${NC}"
    echo "  Package tier:  ${BOLD}${PACKAGE_TIER}${NC}"
    echo "  Shell:         ${BOLD}${ZERA_SHELL:-fish}${NC}"
    echo "  Features:      ${BOLD}${ZERA_FEATURES:-none}${NC}"
    echo ""
    
    if [[ "$DRY_RUN" == true ]]; then
        log "Would confirm with user"
        return 0
    fi
    
    if confirm "Proceed with installation?"; then
        success "Configuration confirmed"
        return 0
    else
        warn "Installation cancelled by user"
        exit 0
    fi
}

# -----------------------------------------------------
# Run All Prompts
# -----------------------------------------------------

configure_hostname
configure_packages
configure_features
configure_shell
confirm_choices

echo ""
success "Configuration complete!"
