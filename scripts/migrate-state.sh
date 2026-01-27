#!/bin/bash
# -----------------------------------------------------
# MIGRATE STATE
# -----------------------------------------------------
# Migrates legacy flat state/ directory to hostname-based structure
# Run once to migrate existing state files

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
STATE_DIR="$DOTFILES_DIR/state"

# Get hostname using multiple methods
if command -v hostname &>/dev/null; then
    MACHINE_NAME=$(hostname)
elif [ -f /etc/hostname ]; then
    MACHINE_NAME=$(cat /etc/hostname | tr -d '[:space:]')
elif command -v hostnamectl &>/dev/null; then
    MACHINE_NAME=$(hostnamectl --static 2>/dev/null || echo "unknown")
else
    MACHINE_NAME="unknown"
fi
NEW_STATE_DIR="$STATE_DIR/$MACHINE_NAME"

echo "Migrating state files to hostname-based structure..."
echo "  Machine: $MACHINE_NAME"
echo "  From: $STATE_DIR/*"
echo "  To:   $NEW_STATE_DIR/"
echo ""

# Check if already migrated
if [ -d "$NEW_STATE_DIR" ] && [ -f "$NEW_STATE_DIR/packages-pacman.txt" ]; then
    echo "Already migrated! State exists at $NEW_STATE_DIR"
    exit 0
fi

# Check if there's anything to migrate
if [ ! -f "$STATE_DIR/packages-pacman.txt" ]; then
    echo "No legacy state files found. Nothing to migrate."
    echo "Run ./scripts/capture-state.sh to create new state."
    exit 0
fi

# Create new directory
mkdir -p "$NEW_STATE_DIR"
mkdir -p "$NEW_STATE_DIR/systemd-services"
mkdir -p "$NEW_STATE_DIR/systemd-user-services"

# Move files (not directories that are already machine dirs)
for file in "$STATE_DIR"/*; do
    name=$(basename "$file")
    
    # Skip if it's a directory that looks like a hostname
    if [ -d "$file" ] && [ "$name" != "systemd-services" ] && [ "$name" != "systemd-user-services" ]; then
        echo "  Skipping directory: $name (might be another machine)"
        continue
    fi
    
    # Move files
    if [ -f "$file" ]; then
        echo "  Moving: $name"
        mv "$file" "$NEW_STATE_DIR/"
    fi
    
    # Move service directories
    if [ -d "$file" ] && [ "$name" = "systemd-services" ]; then
        echo "  Moving: $name/"
        mv "$file"/* "$NEW_STATE_DIR/systemd-services/" 2>/dev/null || true
        rmdir "$file" 2>/dev/null || true
    fi
    
    if [ -d "$file" ] && [ "$name" = "systemd-user-services" ]; then
        echo "  Moving: $name/"
        mv "$file"/* "$NEW_STATE_DIR/systemd-user-services/" 2>/dev/null || true
        rmdir "$file" 2>/dev/null || true
    fi
done

echo ""
echo "Migration complete!"
echo ""
echo "New structure:"
ls -la "$NEW_STATE_DIR/"
echo ""
echo "Don't forget to commit:"
echo "  git add state/"
echo "  git commit -m 'Migrate state to hostname-based structure'"
