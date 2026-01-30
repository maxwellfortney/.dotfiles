#!/bin/bash
# -----------------------------------------------------
# ZERA - System Configuration
# -----------------------------------------------------
# Configures system settings (hostname, locale, groups, etc.)
# This script is sourced by install.sh

# Ensure common functions are available
[[ -z "${ZERA_COMMON_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/../helpers/common.sh"

log "Configuring system settings..."

# -----------------------------------------------------
# Set Hostname
# -----------------------------------------------------

configure_hostname() {
    section "Hostname"
    
    local new_hostname="${ZERA_HOSTNAME:-$(get_hostname)}"
    local current_hostname
    current_hostname=$(get_hostname)
    
    if [[ "$new_hostname" == "$current_hostname" ]]; then
        success "Hostname already set: $current_hostname"
        return 0
    fi
    
    if [[ "$DRY_RUN" == true ]]; then
        log "Would set hostname to: $new_hostname"
        return 0
    fi
    
    log "Setting hostname to: $new_hostname"
    sudo hostnamectl set-hostname "$new_hostname"
    success "Hostname set to $new_hostname"
}

# -----------------------------------------------------
# Configure User Groups
# -----------------------------------------------------

configure_groups() {
    section "User Groups"
    
    # Groups the user should be in for full functionality
    local required_groups=(
        wheel      # sudo access
        video      # GPU access
        audio      # audio devices
        input      # input devices
        storage    # storage access
        optical    # CD/DVD access
    )
    
    # Optional groups based on features
    if [[ "$ZERA_FEATURES" == *"development"* ]]; then
        required_groups+=(docker)
    fi
    
    if is_installed libvirt; then
        required_groups+=(libvirt kvm)
    fi
    
    local added=0
    
    for group in "${required_groups[@]}"; do
        # Check if group exists
        if ! getent group "$group" &>/dev/null; then
            continue
        fi
        
        # Check if user is already in group
        if groups "$USER" 2>/dev/null | grep -qw "$group"; then
            success "Already in group: $group"
            continue
        fi
        
        if [[ "$DRY_RUN" == true ]]; then
            log "Would add $USER to group: $group"
            continue
        fi
        
        log "Adding $USER to group: $group"
        if sudo usermod -aG "$group" "$USER"; then
            success "Added to group: $group"
            ((added++)) || true
        else
            warn "Failed to add to group: $group"
        fi
    done
    
    if [[ $added -gt 0 ]]; then
        info "Log out and back in for group changes to take effect"
    fi
}

# -----------------------------------------------------
# Configure Default Shell
# -----------------------------------------------------

configure_shell() {
    section "Default Shell"
    
    local target_shell="${ZERA_SHELL:-fish}"
    local shell_path
    
    case "$target_shell" in
        fish) shell_path="/usr/bin/fish" ;;
        zsh) shell_path="/usr/bin/zsh" ;;
        bash) shell_path="/bin/bash" ;;
        *) shell_path="/usr/bin/fish" ;;
    esac
    
    # Check if shell is installed
    if [[ ! -x "$shell_path" ]]; then
        warn "Shell not found: $shell_path"
        return 0
    fi
    
    # Check current shell
    local current_shell
    current_shell=$(getent passwd "$USER" | cut -d: -f7)
    
    if [[ "$current_shell" == "$shell_path" ]]; then
        success "Default shell already set: $target_shell"
        return 0
    fi
    
    if [[ "$DRY_RUN" == true ]]; then
        log "Would change default shell to: $shell_path"
        return 0
    fi
    
    log "Changing default shell to: $target_shell"
    if sudo chsh -s "$shell_path" "$USER"; then
        success "Default shell changed to $target_shell"
    else
        warn "Failed to change default shell"
    fi
}

# -----------------------------------------------------
# Configure Locale (if not set)
# -----------------------------------------------------

configure_locale() {
    section "Locale"
    
    # Check if locale is already set
    if [[ -n "$LANG" ]] && localectl status | grep -q "LANG=$LANG"; then
        success "Locale already configured: $LANG"
        return 0
    fi
    
    local target_locale="en_US.UTF-8"
    
    if [[ "$DRY_RUN" == true ]]; then
        log "Would ensure locale is set to: $target_locale"
        return 0
    fi
    
    # Ensure locale is generated
    if ! locale -a | grep -qi "en_US.utf8"; then
        log "Generating locale..."
        sudo sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
        sudo locale-gen
    fi
    
    # Set locale
    echo "LANG=$target_locale" | sudo tee /etc/locale.conf > /dev/null
    success "Locale configured: $target_locale"
}

# -----------------------------------------------------
# Configure Timezone (if not set)
# -----------------------------------------------------

configure_timezone() {
    section "Timezone"
    
    local current_tz
    current_tz=$(timedatectl show --property=Timezone --value 2>/dev/null || echo "")
    
    if [[ -n "$current_tz" && "$current_tz" != "UTC" ]]; then
        success "Timezone already configured: $current_tz"
        return 0
    fi
    
    if [[ "$DRY_RUN" == true ]]; then
        log "Would prompt for timezone configuration"
        return 0
    fi
    
    # Try to auto-detect timezone
    local detected_tz
    detected_tz=$(curl -s https://ipapi.co/timezone 2>/dev/null || echo "")
    
    if [[ -n "$detected_tz" ]]; then
        log "Detected timezone: $detected_tz"
        if confirm "Use detected timezone?"; then
            sudo timedatectl set-timezone "$detected_tz"
            success "Timezone set to $detected_tz"
            return 0
        fi
    fi
    
    # Manual selection
    info "Select timezone using timedatectl set-timezone <zone>"
}

# -----------------------------------------------------
# Enable zram (swap compression)
# -----------------------------------------------------

configure_zram() {
    section "Memory Configuration"
    
    if ! is_installed zram-generator; then
        info "zram-generator not installed, skipping"
        return 0
    fi
    
    local zram_conf="/etc/systemd/zram-generator.conf"
    
    if [[ -f "$zram_conf" ]]; then
        success "zram already configured"
        return 0
    fi
    
    if [[ "$DRY_RUN" == true ]]; then
        log "Would configure zram"
        return 0
    fi
    
    log "Configuring zram..."
    
    sudo tee "$zram_conf" > /dev/null << 'EOF'
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
EOF
    
    success "zram configured (will activate on reboot)"
}

# -----------------------------------------------------
# Run Configuration
# -----------------------------------------------------

configure_hostname
configure_groups
configure_shell
configure_locale
configure_timezone
configure_zram

echo ""
success "System configuration complete!"
