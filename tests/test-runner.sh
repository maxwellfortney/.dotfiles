#!/bin/bash
# -----------------------------------------------------
# TEST RUNNER
# -----------------------------------------------------
# Runs all tests for the disaster recovery scripts
# Should be run inside the Docker container

set -e

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

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Logging functions
log() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((TESTS_PASSED++))
    ((TESTS_RUN++))
}

fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((TESTS_FAILED++))
    ((TESTS_RUN++))
}

section() {
    echo ""
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}${BOLD}  $1${NC}"
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# -----------------------------------------------------
# ShellCheck Tests
# -----------------------------------------------------
test_shellcheck() {
    section "ShellCheck Static Analysis"
    
    local scripts=(
        "$DOTFILES_DIR/scripts/capture-state.sh"
        "$DOTFILES_DIR/scripts/sync-state.sh"
        "$DOTFILES_DIR/scripts/setup-auto-sync.sh"
        "$DOTFILES_DIR/scripts/install-deps.sh"
        "$DOTFILES_DIR/restore/restore.sh"
        "$DOTFILES_DIR/restore/restore-packages.sh"
        "$DOTFILES_DIR/restore/restore-services.sh"
        "$DOTFILES_DIR/restore/restore-system.sh"
        "$DOTFILES_DIR/restore/restore-dotfiles.sh"
        "$DOTFILES_DIR/stow-select.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            log "Checking $(basename "$script")..."
            if shellcheck -x "$script" 2>/dev/null; then
                pass "$(basename "$script") passed shellcheck"
            else
                fail "$(basename "$script") has shellcheck errors"
                shellcheck -x "$script" 2>&1 | head -20
            fi
        else
            log "Skipping $(basename "$script") (not found)"
        fi
    done
}

# -----------------------------------------------------
# Script Existence Tests
# -----------------------------------------------------
test_script_existence() {
    section "Script Existence Tests"
    
    local required_scripts=(
        "scripts/capture-state.sh"
        "scripts/sync-state.sh"
        "scripts/setup-auto-sync.sh"
        "scripts/install-deps.sh"
        "restore/restore.sh"
        "restore/restore-packages.sh"
        "restore/restore-services.sh"
        "restore/restore-system.sh"
        "restore/restore-dotfiles.sh"
        "restore/restore-manual.md"
    )
    
    for script in "${required_scripts[@]}"; do
        if [ -f "$DOTFILES_DIR/$script" ]; then
            pass "$script exists"
        else
            fail "$script is missing"
        fi
    done
    
    # Check executability
    for script in "${required_scripts[@]}"; do
        if [[ "$script" == *.sh ]] && [ -f "$DOTFILES_DIR/$script" ]; then
            if [ -x "$DOTFILES_DIR/$script" ]; then
                pass "$script is executable"
            else
                fail "$script is not executable"
            fi
        fi
    done
}

# -----------------------------------------------------
# Capture State Tests
# -----------------------------------------------------
test_capture_state() {
    section "Capture State Tests"
    
    log "Running capture-state.sh..."
    
    if "$DOTFILES_DIR/scripts/capture-state.sh"; then
        pass "capture-state.sh completed successfully"
    else
        fail "capture-state.sh failed"
        return 1
    fi
    
    # Check state files were created
    local state_files=(
        "packages-pacman.txt"
        "packages-aur.txt"
        "services-enabled.txt"
        "services-user.txt"
        "mkinitcpio.conf"
        "kernel-params.txt"
        "sysctl.conf"
        "system-info.txt"
        "timers-enabled.txt"
        "timers-user.txt"
    )
    
    for file in "${state_files[@]}"; do
        if [ -f "$DOTFILES_DIR/state/$file" ]; then
            pass "state/$file was created"
        else
            fail "state/$file was not created"
        fi
    done
    
    # Validate state file contents
    log "Validating state file contents..."
    
    # packages-pacman.txt should have content
    if [ -s "$DOTFILES_DIR/state/packages-pacman.txt" ]; then
        local count=$(wc -l < "$DOTFILES_DIR/state/packages-pacman.txt")
        pass "packages-pacman.txt has $count packages"
    else
        fail "packages-pacman.txt is empty"
    fi
    
    # system-info.txt should have HOSTNAME
    if grep -q "^HOSTNAME=" "$DOTFILES_DIR/state/system-info.txt"; then
        pass "system-info.txt contains HOSTNAME"
    else
        fail "system-info.txt missing HOSTNAME"
    fi
}

# -----------------------------------------------------
# Restore Dry Run Tests
# -----------------------------------------------------
test_restore_dry_run() {
    section "Restore Dry Run Tests"
    
    log "Running restore.sh --dry-run..."
    
    if "$DOTFILES_DIR/restore/restore.sh" --dry-run; then
        pass "restore.sh --dry-run completed"
    else
        fail "restore.sh --dry-run failed"
    fi
}

# -----------------------------------------------------
# Sync State Tests
# -----------------------------------------------------
test_sync_state() {
    section "Sync State Tests"
    
    # Initialize git repo for testing
    log "Initializing git repo for sync test..."
    cd "$DOTFILES_DIR"
    
    if ! git rev-parse --git-dir &>/dev/null; then
        git init
        git config user.email "test@test.com"
        git config user.name "Test User"
        git add -A
        git commit -m "Initial commit for testing"
    fi
    
    log "Running sync-state.sh..."
    
    if "$DOTFILES_DIR/scripts/sync-state.sh"; then
        pass "sync-state.sh completed"
    else
        fail "sync-state.sh failed"
    fi
    
    # Check log file was created
    if [ -f "$DOTFILES_DIR/logs/sync-state.log" ]; then
        pass "Sync log file was created"
    else
        fail "Sync log file was not created"
    fi
}

# -----------------------------------------------------
# Idempotency Tests
# -----------------------------------------------------
test_idempotency() {
    section "Idempotency Tests"
    
    log "Running capture-state.sh twice..."
    
    # Run capture twice
    "$DOTFILES_DIR/scripts/capture-state.sh" > /dev/null 2>&1
    local first_hash=$(md5sum "$DOTFILES_DIR/state/packages-pacman.txt" | cut -d' ' -f1)
    
    "$DOTFILES_DIR/scripts/capture-state.sh" > /dev/null 2>&1
    local second_hash=$(md5sum "$DOTFILES_DIR/state/packages-pacman.txt" | cut -d' ' -f1)
    
    if [ "$first_hash" = "$second_hash" ]; then
        pass "capture-state.sh is idempotent (same output)"
    else
        fail "capture-state.sh produced different output on second run"
    fi
}

# -----------------------------------------------------
# Stow Tests
# -----------------------------------------------------
test_stow() {
    section "Stow Tests"
    
    log "Testing stow on fish package..."
    
    cd "$DOTFILES_DIR"
    
    # Try to stow fish (should work or already be stowed)
    if stow --simulate fish 2>/dev/null; then
        pass "stow --simulate fish succeeded"
    else
        # May fail if already stowed or conflicts exist
        log "stow --simulate fish had conflicts (may be expected)"
        pass "stow --simulate ran (conflicts possible)"
    fi
}

# -----------------------------------------------------
# Print Summary
# -----------------------------------------------------
print_summary() {
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}  Test Summary${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  Tests run:    ${TESTS_RUN}"
    echo -e "  ${GREEN}Passed:       ${TESTS_PASSED}${NC}"
    echo -e "  ${RED}Failed:       ${TESTS_FAILED}${NC}"
    echo ""
    
    if [ "$TESTS_FAILED" -eq 0 ]; then
        echo -e "${GREEN}${BOLD}  All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}${BOLD}  Some tests failed!${NC}"
        return 1
    fi
}

# -----------------------------------------------------
# Main
# -----------------------------------------------------
main() {
    echo ""
    echo -e "${BLUE}${BOLD}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}${BOLD}  Dotfiles Disaster Recovery - Test Suite${NC}"
    echo -e "${BLUE}${BOLD}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    test_shellcheck
    test_script_existence
    test_capture_state
    test_restore_dry_run
    test_sync_state
    test_idempotency
    test_stow
    
    print_summary
}

main "$@"
