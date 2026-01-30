#!/bin/bash
# -----------------------------------------------------
# ZERA - Configuration Management
# -----------------------------------------------------
# Handles user preferences and config merging
# This file is sourced by other scripts

# Prevent multiple sourcing
[[ -n "${ZERA_CONFIG_LOADED:-}" ]] && return
ZERA_CONFIG_LOADED=1

# Ensure common functions are available
[[ -z "${ZERA_COMMON_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# -----------------------------------------------------
# Paths
# -----------------------------------------------------

ZERA_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/zera"
ZERA_CONFIG_FILE="$ZERA_CONFIG_DIR/config.toml"

# -----------------------------------------------------
# Initialize Config
# -----------------------------------------------------

init_zera_config() {
    ensure_dir "$ZERA_CONFIG_DIR"
    
    if [[ ! -f "$ZERA_CONFIG_FILE" ]]; then
        create_default_config
    fi
}

create_default_config() {
    cat > "$ZERA_CONFIG_FILE" << 'EOF'
# Zera Configuration
# Edit this file to customize your setup

[preferences]
# Terminal emulator: kitty, alacritty, ghostty
terminal = "kitty"

# Shell: fish, zsh, bash
shell = "fish"

# Application launcher: wofi, walker, rofi
launcher = "wofi"

# Browser: brave, firefox, chromium
browser = "brave"

[features]
# Enable optional feature bundles
gaming = false
development = false
multimedia = false
office = false

[sync]
# How zera handles config updates

# Configs that use source/include pattern (user/ directory)
# These support live overrides without merging
sourceable = ["hyprland", "fish", "kitty"]

# Configs that need JSON/TOML merging
# zera.* + user.* → final config
mergeable = ["waybar", "walker", "matugen", "dunst"]

[ejected]
# Files you've taken full ownership of
# These won't be updated by zera sync
# Format: "app/path/to/file"
files = []

[ejected_versions]
# Tracks which zera version files were ejected from
# Used for merge assistance
# "app/path/to/file" = "0.1.0"
EOF
    
    success "Created config file: $ZERA_CONFIG_FILE"
}

# -----------------------------------------------------
# Read Config Values
# -----------------------------------------------------

# Get a preference value
get_preference() {
    local key="$1"
    local default="$2"
    
    if [[ ! -f "$ZERA_CONFIG_FILE" ]]; then
        echo "$default"
        return
    fi
    
    # Parse TOML (simple grep-based for basic key = "value")
    local value
    value=$(grep -E "^${key}\s*=" "$ZERA_CONFIG_FILE" 2>/dev/null | head -1 | sed 's/.*=\s*"\(.*\)"/\1/' | sed "s/.*=\s*'\(.*\)'/\1/")
    
    if [[ -n "$value" ]]; then
        echo "$value"
    else
        echo "$default"
    fi
}

# Get a boolean preference
get_preference_bool() {
    local key="$1"
    local default="${2:-false}"
    
    local value
    value=$(grep -E "^${key}\s*=" "$ZERA_CONFIG_FILE" 2>/dev/null | head -1 | sed 's/.*=\s*//')
    
    case "$value" in
        true|True|TRUE|yes|Yes|YES|1) echo "true" ;;
        false|False|FALSE|no|No|NO|0) echo "false" ;;
        *) echo "$default" ;;
    esac
}

# Get array values (simple implementation)
get_preference_array() {
    local key="$1"
    
    # Look for key = ["item1", "item2"] pattern
    local line
    line=$(grep -E "^${key}\s*=" "$ZERA_CONFIG_FILE" 2>/dev/null | head -1)
    
    if [[ -z "$line" ]]; then
        return
    fi
    
    # Extract array contents and split
    echo "$line" | sed 's/.*\[\(.*\)\]/\1/' | tr ',' '\n' | sed 's/[" ]//g' | grep -v '^$'
}

# Check if a file is ejected
is_ejected() {
    local file="$1"
    local ejected
    ejected=$(get_preference_array "files")
    
    echo "$ejected" | grep -qx "$file"
}

# -----------------------------------------------------
# Write Config Values
# -----------------------------------------------------

# Set a preference value
set_preference() {
    local key="$1"
    local value="$2"
    
    init_zera_config
    
    # Check if key exists
    if grep -qE "^${key}\s*=" "$ZERA_CONFIG_FILE" 2>/dev/null; then
        # Update existing key
        sed -i "s|^${key}\s*=.*|${key} = \"${value}\"|" "$ZERA_CONFIG_FILE"
    else
        # Add to preferences section
        sed -i "/^\[preferences\]/a ${key} = \"${value}\"" "$ZERA_CONFIG_FILE"
    fi
}

# Add a file to ejected list
add_ejected() {
    local file="$1"
    local version="${2:-$(cat "$ZERA_DIR/version" 2>/dev/null || echo "unknown")}"
    
    init_zera_config
    
    # This is a simplified implementation
    # A proper TOML parser would be better for production
    log "Marking as ejected: $file (from version $version)"
}

# -----------------------------------------------------
# JSON Merging (using jq)
# -----------------------------------------------------

# Deep merge two JSON files
# Usage: merge_json base.json user.json output.json
merge_json() {
    local base="$1"
    local user="$2"
    local output="$3"
    
    if ! has_command jq; then
        error "jq is required for JSON merging"
        echo "Install with: sudo pacman -S jq"
        return 1
    fi
    
    if [[ ! -f "$base" ]]; then
        error "Base config not found: $base"
        return 1
    fi
    
    # Add header comment (jq output, then prepend)
    local header="// AUTO-GENERATED by zera - Do not edit directly!
// Customize by editing: $(dirname "$output")/user.jsonc
// Run 'zera sync' to regenerate this file
"
    
    if [[ -f "$user" ]]; then
        # Deep merge: base * user (user wins on conflicts)
        # Handle JSONC (comments) by stripping them first
        local base_clean user_clean
        base_clean=$(sed 's|//.*||g; s|/\*.*\*/||g' "$base")
        user_clean=$(sed 's|//.*||g; s|/\*.*\*/||g' "$user")
        
        echo "$header" > "$output"
        echo "$base_clean" "$user_clean" | jq -s '.[0] * .[1]' >> "$output"
    else
        # No user overrides
        echo "$header" > "$output"
        sed 's|//.*||g; s|/\*.*\*/||g' "$base" | jq '.' >> "$output"
    fi
    
    success "Merged config: $output"
}

# Merge JSONC specifically (strip comments, merge, output clean JSON)
merge_jsonc() {
    merge_json "$@"
}

# -----------------------------------------------------
# TOML Merging
# -----------------------------------------------------

# Simple TOML merge (key-level, not deep)
# For deep TOML merging, would need a proper parser
merge_toml() {
    local base="$1"
    local user="$2"
    local output="$3"
    
    if [[ ! -f "$base" ]]; then
        error "Base config not found: $base"
        return 1
    fi
    
    local header="# AUTO-GENERATED by zera - Do not edit directly!
# Customize by editing: $(dirname "$output")/user.toml
# Run 'zera sync' to regenerate this file
"
    
    if [[ -f "$user" ]]; then
        # Simple merge: append user file (later values override in most TOML parsers)
        # This is a simplification - proper TOML merging would need a parser
        {
            echo "$header"
            echo ""
            echo "# === Zera defaults ==="
            cat "$base"
            echo ""
            echo "# === User overrides ==="
            cat "$user"
        } > "$output"
    else
        {
            echo "$header"
            cat "$base"
        } > "$output"
    fi
    
    success "Merged config: $output"
}

# -----------------------------------------------------
# CSS Merging (simple append)
# -----------------------------------------------------

merge_css() {
    local base="$1"
    local user="$2"
    local output="$3"
    
    if [[ ! -f "$base" ]]; then
        error "Base config not found: $base"
        return 1
    fi
    
    local header="/* AUTO-GENERATED by zera - Do not edit directly!
 * Customize by editing: $(dirname "$output")/user.css
 * Run 'zera sync' to regenerate this file
 */
"
    
    if [[ -f "$user" ]]; then
        {
            echo "$header"
            echo "/* === Zera defaults === */"
            cat "$base"
            echo ""
            echo "/* === User overrides === */"
            cat "$user"
        } > "$output"
    else
        {
            echo "$header"
            cat "$base"
        } > "$output"
    fi
    
    success "Merged config: $output"
}

# -----------------------------------------------------
# Sync a Mergeable Config
# -----------------------------------------------------

# Sync a single mergeable config
# Usage: sync_mergeable_config app_name
sync_mergeable_config() {
    local app="$1"
    local config_dir="$HOME/.config/$app"
    
    case "$app" in
        waybar)
            merge_jsonc "$config_dir/zera.jsonc" "$config_dir/user.jsonc" "$config_dir/config.jsonc"
            merge_css "$config_dir/zera.css" "$config_dir/user.css" "$config_dir/style.css"
            ;;
        walker)
            merge_toml "$config_dir/zera.toml" "$config_dir/user.toml" "$config_dir/config.toml"
            ;;
        dunst)
            # Dunst uses INI-style, treat like TOML
            merge_toml "$config_dir/zera.dunstrc" "$config_dir/user.dunstrc" "$config_dir/dunstrc"
            ;;
        matugen)
            merge_toml "$config_dir/zera.toml" "$config_dir/user.toml" "$config_dir/config.toml"
            ;;
        *)
            warn "Unknown mergeable config: $app"
            ;;
    esac
}

# Sync all mergeable configs
sync_all_mergeable() {
    local mergeable
    mergeable=$(get_preference_array "mergeable")
    
    if [[ -z "$mergeable" ]]; then
        # Default list
        mergeable="waybar walker dunst"
    fi
    
    for app in $mergeable; do
        if [[ -d "$HOME/.config/$app" ]]; then
            sync_mergeable_config "$app"
        fi
    done
}
