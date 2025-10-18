#!/bin/bash

# Simple dotfiles stow helper using fzf or whiptail
# Much simpler and more reliable than custom arrow key handling

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if stow is installed
check_stow() {
    if ! command -v stow &> /dev/null; then
        print_status $RED "Error: stow is not installed!"
        print_status $YELLOW "Install it with: sudo pacman -S stow"
        exit 1
    fi
}

# Function to get directories from git
get_git_dirs() {
    # Get directories that are tracked by git
    git ls-tree -d --name-only HEAD | grep -v '^$'
}

# Function to stow selected directories
stow_selected() {
    local selected=("$@")
    
    if [ ${#selected[@]} -eq 0 ]; then
        print_status $YELLOW "No directories selected"
        return
    fi
    
    print_status $BLUE "Stowing selected directories..."
    echo
    
    for dir in "${selected[@]}"; do
        print_status $YELLOW "Stowing $dir..."
        if stow "$dir"; then
            print_status $GREEN "✓ Successfully stowed $dir"
        else
            print_status $RED "✗ Failed to stow $dir"
        fi
    done
    
    echo
    print_status $GREEN "Done!"
}

# Function using fzf (best option)
use_fzf() {
    print_status $BLUE "Select directories to stow (use Ctrl+A to select all, Tab to toggle, Enter to confirm):"
    echo
    
    local selected
    selected=$(get_git_dirs | fzf --multi --height=20 --border --header="Select dotfiles to stow" --prompt="> " --pointer=">" --marker="✓")
    
    if [ -n "$selected" ]; then
        # Convert newline-separated string to array
        local dirs=()
        while IFS= read -r dir; do
            dirs+=("$dir")
        done <<< "$selected"
        
        stow_selected "${dirs[@]}"
    else
        print_status $YELLOW "No directories selected"
    fi
}

# Function using whiptail (fallback)
use_whiptail() {
    local dirs=()
    while IFS= read -r dir; do
        dirs+=("$dir")
    done < <(get_git_dirs)
    
    if [ ${#dirs[@]} -eq 0 ]; then
        print_status $RED "No directories found in git repository"
        exit 1
    fi
    
    # Create whiptail options
    local options=()
    for i in "${!dirs[@]}"; do
        options+=("$((i+1))" "${dirs[$i]}" "OFF")
    done
    
    local selected
    selected=$(whiptail --title "Select Directories to Stow" --checklist "Choose directories to stow:" 20 60 10 "${options[@]}" 3>&1 1>&2 2>&3)
    
    if [ $? -eq 0 ] && [ -n "$selected" ]; then
        # Parse selected indices
        local to_stow=()
        for index in $selected; do
            # Remove quotes and convert to 0-based index
            index=$(echo "$index" | tr -d '"')
            local dir_index=$((index-1))
            to_stow+=("${dirs[$dir_index]}")
        done
        
        stow_selected "${to_stow[@]}"
    else
        print_status $YELLOW "No directories selected"
    fi
}

# Function using simple bash select (fallback)
use_select() {
    local dirs=()
    while IFS= read -r dir; do
        dirs+=("$dir")
    done < <(get_git_dirs)
    
    if [ ${#dirs[@]} -eq 0 ]; then
        print_status $RED "No directories found in git repository"
        exit 1
    fi
    
    print_status $BLUE "Select directories to stow (enter numbers separated by spaces, then press enter):"
    echo
    
    # Show numbered list
    for i in "${!dirs[@]}"; do
        echo "$((i+1)). ${dirs[$i]}"
    done
    
    echo
    read -p "Enter selection (e.g., 1 3 5): " selection
    
    if [ -n "$selection" ]; then
        local to_stow=()
        for num in $selection; do
            if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "${#dirs[@]}" ]; then
                local index=$((num-1))
                to_stow+=("${dirs[$index]}")
            fi
        done
        
        stow_selected "${to_stow[@]}"
    else
        print_status $YELLOW "No directories selected"
    fi
}

# Main script
main() {
    # Change to dotfiles directory
    cd "$HOME/.dotfiles" || {
        print_status $RED "Error: Could not change to ~/.dotfiles directory"
        exit 1
    }
    
    check_stow
    
    # Try to use the best available tool
    if command -v fzf &> /dev/null; then
        print_status $GREEN "Using fzf (fuzzy finder)"
        use_fzf
    elif command -v whiptail &> /dev/null; then
        print_status $GREEN "Using whiptail"
        use_whiptail
    else
        print_status $YELLOW "Using basic selection (install fzf or whiptail for better experience)"
        use_select
    fi
}

# Run main function
main "$@"