#!/bin/bash

# hyprsunset Waybar module
# Shows current temperature in Kelvin and allows adjustment via scroll
# Author: Custom module for Waybar
# Version: 1.0

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# =============================================================================
# Configuration
# =============================================================================

readonly TEMP_STEP="${TEMP_STEP:-200}"        # Temperature step for scrolling
readonly DEFAULT_TEMP="${DEFAULT_TEMP:-6500}"  # Default temperature for reset
readonly MIN_TEMP=1000                         # Minimum temperature (very warm)
readonly MAX_TEMP=6500                        # Maximum temperature (default)
readonly HYPRSUNSET_CMD="hyprsunset"
readonly HYPRCTL_CMD="hyprctl"

# =============================================================================
# Utility Functions
# =============================================================================

# Check if hyprsunset is running
is_hyprsunset_running() {
    pgrep -x "$HYPRSUNSET_CMD" >/dev/null 2>&1
}

# Log error messages to stderr
log_error() {
    echo "ERROR: $*" >&2
}

# Validate temperature is within valid range
validate_temp() {
    local temp="$1"
    if ! [[ "$temp" =~ ^[0-9]+$ ]] || [ "$temp" -lt "$MIN_TEMP" ] || [ "$temp" -gt "$MAX_TEMP" ]; then
        return 1
    fi
    return 0
}

# Clamp temperature to valid range
clamp_temp() {
    local temp="$1"
    if [ "$temp" -lt "$MIN_TEMP" ]; then
        echo "$MIN_TEMP"
    elif [ "$temp" -gt "$MAX_TEMP" ]; then
        echo "$MAX_TEMP"
    else
        echo "$temp"
    fi
}

# =============================================================================
# Core Functions
# =============================================================================

# Get current temperature from hyprsunset
get_current_temp() {
    if ! is_hyprsunset_running; then
        echo "$DEFAULT_TEMP"
        return 0
    fi
    
    local temp_output
    if ! temp_output=$("$HYPRCTL_CMD" hyprsunset temperature 2>/dev/null); then
        echo "$DEFAULT_TEMP"
        return 0
    fi
    
    # Extract temperature from output
    local temp
    temp=$(echo "$temp_output" | grep -o '[0-9]\+' | head -1)
    
    # Check if temperature is valid or if in identity mode
    if [ -z "$temp" ] || [ "$temp" = "0" ] || echo "$temp_output" | grep -q "identity"; then
        echo "$DEFAULT_TEMP"
    else
        echo "$temp"
    fi
}

# Set temperature via hyprctl
set_temp() {
    local new_temp="$1"
    
    # Clamp temperature to valid range
    new_temp=$(clamp_temp "$new_temp")
    
    # Start hyprsunset if not running
    if ! is_hyprsunset_running; then
        if ! "$HYPRSUNSET_CMD" >/dev/null 2>&1 & then
            log_error "Failed to start hyprsunset"
            return 1
        fi
        sleep 1  # Give it a moment to start
    fi
    
    # Set temperature via hyprctl
    if ! "$HYPRCTL_CMD" hyprsunset temperature "$new_temp" >/dev/null 2>&1; then
        log_error "Failed to set temperature to $new_temp"
        return 1
    fi
    
    echo "$new_temp"
}


# =============================================================================
# Event Handlers
# =============================================================================

# Handle scroll events
handle_scroll() {
    local direction="$1"
    local step_size="${2:-$TEMP_STEP}"
    
    # Validate step size
    if ! [[ "$step_size" =~ ^[0-9]+$ ]] || [ "$step_size" -le 0 ]; then
        log_error "Invalid step size: $step_size"
        exit 1
    fi
    
    local current_temp
    current_temp=$(get_current_temp)
    
    local new_temp
    case "$direction" in
        "up")
            new_temp=$((current_temp + step_size))
            ;;
        "down")
            new_temp=$((current_temp - step_size))
            ;;
        *)
            log_error "Invalid scroll direction: $direction"
            exit 1
            ;;
    esac
    
    # Check if we would exceed limits before setting
    local clamped_temp
    clamped_temp=$(clamp_temp "$new_temp")
    
    # Set the temperature (will be clamped if needed)
    set_temp "$new_temp"
    
    # Provide feedback if we hit a limit
    if [ "$clamped_temp" != "$new_temp" ]; then
        if [ "$clamped_temp" = "$MIN_TEMP" ]; then
            log_error "Temperature clamped to minimum: ${MIN_TEMP}K"
        elif [ "$clamped_temp" = "$MAX_TEMP" ]; then
            log_error "Temperature clamped to maximum: ${MAX_TEMP}K"
        fi
    fi
}

# Handle click events (reset to default)
handle_click() {
    set_temp "$DEFAULT_TEMP"
}

# Handle step parameter (for easy adjustment)
handle_step() {
    local new_step="$1"
    
    if ! [[ "$new_step" =~ ^[0-9]+$ ]] || [ "$new_step" -le 0 ]; then
        log_error "Invalid step size: $new_step"
        exit 1
    fi
    
    echo "Step size set to: $new_step"
}

# =============================================================================
# Main Logic
# =============================================================================

main() {
    case "${1:-}" in
        "scroll")
            if [ -z "${2:-}" ]; then
                log_error "Scroll direction required"
                exit 1
            fi
            handle_scroll "$2" "${3:-$TEMP_STEP}"
            ;;
        "click")
            handle_click
            ;;
        "step")
            if [ -z "${2:-}" ]; then
                log_error "Step size required"
                exit 1
            fi
            handle_step "$2"
            ;;
        "")
            # Display mode - show current temperature
            local current_temp kelvin
            
            current_temp=$(get_current_temp)
            kelvin="$current_temp"  # Temperature is already in Kelvin
            
            # Output JSON for Waybar
            if ! is_hyprsunset_running; then
                printf '{"text": "OFF %sK 󰌵", "class": "hyprsunset"}\n' "$kelvin"
            else
                printf '{"text": "%sK 󰌵", "class": "hyprsunset"}\n' "$kelvin"
            fi
            ;;
        *)
            log_error "Unknown command: $1"
            echo "Usage: $0 [scroll <up|down> [step]] [click] [step <size>]"
            exit 1
            ;;
    esac
}

# =============================================================================
# Script Entry Point
# =============================================================================

main "$@"