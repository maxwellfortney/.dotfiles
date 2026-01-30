#!/bin/bash
# -----------------------------------------------------
# ZERA - Service Enablement
# -----------------------------------------------------
# Enables systemd services required for the setup
# This script is sourced by install.sh

# Ensure common functions are available
[[ -z "${ZERA_COMMON_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/../helpers/common.sh"

log "Configuring systemd services..."

# -----------------------------------------------------
# Services to Enable
# -----------------------------------------------------

# System services (run as root)
SYSTEM_SERVICES=(
    "NetworkManager.service"
    "bluetooth.service"
    "sddm.service"
)

# User services (run as current user)
USER_SERVICES=(
    # Add any user services here
)

# -----------------------------------------------------
# Enable System Services
# -----------------------------------------------------

enable_system_services() {
    section "System Services"
    
    for service in "${SYSTEM_SERVICES[@]}"; do
        if [[ "$DRY_RUN" == true ]]; then
            log "Would enable: $service"
            continue
        fi
        
        # Check if already enabled
        if systemctl is-enabled "$service" &>/dev/null; then
            success "$service already enabled"
        else
            log "Enabling $service..."
            if sudo systemctl enable "$service" 2>/dev/null; then
                success "Enabled $service"
            else
                warn "Failed to enable $service"
            fi
        fi
    done
}

# -----------------------------------------------------
# Enable User Services
# -----------------------------------------------------

enable_user_services() {
    if [[ ${#USER_SERVICES[@]} -eq 0 ]]; then
        info "No user services to enable"
        return 0
    fi
    
    section "User Services"
    
    for service in "${USER_SERVICES[@]}"; do
        if [[ "$DRY_RUN" == true ]]; then
            log "Would enable user service: $service"
            continue
        fi
        
        if systemctl --user is-enabled "$service" &>/dev/null; then
            success "$service already enabled"
        else
            log "Enabling user service $service..."
            if systemctl --user enable "$service" 2>/dev/null; then
                success "Enabled $service"
            else
                warn "Failed to enable $service"
            fi
        fi
    done
}

# -----------------------------------------------------
# Feature-specific Services
# -----------------------------------------------------

enable_feature_services() {
    section "Feature Services"
    
    # Docker (if development feature selected)
    if [[ "$ZERA_FEATURES" == *"development"* ]] && is_installed docker; then
        if [[ "$DRY_RUN" != true ]]; then
            if ! systemctl is-enabled docker.service &>/dev/null; then
                sudo systemctl enable docker.service
                success "Enabled docker.service"
            else
                success "docker.service already enabled"
            fi
        else
            log "Would enable docker.service"
        fi
    fi
    
    # Tailscale (if installed)
    if is_installed tailscale; then
        if [[ "$DRY_RUN" != true ]]; then
            if ! systemctl is-enabled tailscaled.service &>/dev/null; then
                sudo systemctl enable tailscaled.service
                success "Enabled tailscaled.service"
            else
                success "tailscaled.service already enabled"
            fi
        else
            log "Would enable tailscaled.service"
        fi
    fi
    
    # libvirtd (if virtualization installed)
    if is_installed libvirt; then
        if [[ "$DRY_RUN" != true ]]; then
            if ! systemctl is-enabled libvirtd.service &>/dev/null; then
                sudo systemctl enable libvirtd.service
                success "Enabled libvirtd.service"
            else
                success "libvirtd.service already enabled"
            fi
        else
            log "Would enable libvirtd.service"
        fi
    fi
}

# -----------------------------------------------------
# Run Service Configuration
# -----------------------------------------------------

enable_system_services
enable_user_services
enable_feature_services

echo ""
success "Service configuration complete!"
info "Services will start after reboot"
