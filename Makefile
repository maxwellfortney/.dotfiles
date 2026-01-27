# Dotfiles Makefile
# Provides targets for testing and common operations

.PHONY: help lint test test-docker build-test-image capture sync install clean \
        vm-setup vm-download-iso vm-create vm-start vm-stop vm-console vm-ssh \
        vm-snapshot vm-reset vm-restore vm-reboot vm-status

# Default target
help:
	@echo "Dotfiles Management"
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@echo "Targets:"
	@echo "  help               Show this help message"
	@echo ""
	@echo "Testing (Docker - headless):"
	@echo "  lint               Run shellcheck on all scripts"
	@echo "  test               Run tests locally (may modify system!)"
	@echo "  test-docker        Run tests in Docker container (safe)"
	@echo "  build-test-image   Build the Docker test image"
	@echo ""
	@echo "Testing (VM - visual, full DE):"
	@echo "  vm-setup           Install VM host dependencies (libvirt/QEMU)"
	@echo "  vm-download-iso    Download latest Arch Linux ISO"
	@echo "  vm-create          Create the test VM (interactive setup)"
	@echo "  vm-start           Start the VM"
	@echo "  vm-stop            Stop the VM gracefully"
	@echo "  vm-console         Open VM console in virt-manager"
	@echo "  vm-ssh             SSH into the VM"
	@echo "  vm-snapshot        Create clean-base snapshot"
	@echo "  vm-reset           Restore VM to clean snapshot"
	@echo "  vm-restore         Run restore.sh in the VM"
	@echo "  vm-reboot          Reboot the VM"
	@echo "  vm-status          Show VM status"
	@echo ""
	@echo "Operations:"
	@echo "  capture            Capture current system state"
	@echo "  sync               Capture state and commit changes"
	@echo "  install            Run full restoration"
	@echo "  install-dry-run    Show what restoration would do"
	@echo ""
	@echo "Maintenance:"
	@echo "  clean              Remove generated files"

# -----------------------------------------------------
# Testing Targets
# -----------------------------------------------------

# Run shellcheck locally (if installed)
lint:
	@echo "Running shellcheck..."
	@command -v shellcheck >/dev/null 2>&1 || { echo "shellcheck not installed. Run: sudo pacman -S shellcheck"; exit 1; }
	shellcheck -x scripts/*.sh restore/*.sh stow-select.sh 2>/dev/null || true
	@echo "Done."

# Run tests locally (WARNING: may modify system)
test:
	@echo "WARNING: This will run tests on your actual system!"
	@echo "Consider using 'make test-docker' instead."
	@read -p "Continue? [y/N] " confirm && [ "$$confirm" = "y" ] || exit 1
	./tests/test-runner.sh

# Build Docker test image
build-test-image:
	@echo "Building Docker test image..."
	docker build -t dotfiles-test -f tests/Dockerfile .

# Build Docker test image without cache
build-test-image-fresh:
	@echo "Building Docker test image (no cache)..."
	docker build --no-cache -t dotfiles-test -f tests/Dockerfile .

# Run tests in Docker (safe)
test-docker: build-test-image
	@echo "Running tests in Docker container..."
	docker run --rm -it dotfiles-test ./tests/test-runner.sh

# Run tests in Docker non-interactively
test-docker-ci: build-test-image
	@echo "Running tests in Docker container (CI mode)..."
	docker run --rm dotfiles-test ./tests/test-runner.sh

# Shell into the test container for debugging
test-shell: build-test-image
	@echo "Starting shell in test container..."
	docker run --rm -it dotfiles-test /bin/bash

# -----------------------------------------------------
# Operation Targets
# -----------------------------------------------------

# Capture current system state
capture:
	./scripts/capture-state.sh

# Capture and commit
sync:
	./scripts/sync-state.sh

# Run full restoration
install:
	@echo "This will restore your system from state files."
	@read -p "Continue? [y/N] " confirm && [ "$$confirm" = "y" ] || exit 1
	./restore/restore.sh

# Dry run restoration
install-dry-run:
	./restore/restore.sh --dry-run

# Install cron job for auto-sync
setup-auto-sync:
	./scripts/setup-auto-sync.sh

# -----------------------------------------------------
# Maintenance Targets
# -----------------------------------------------------

# Remove generated files
clean:
	rm -f logs/*.log
	@echo "Cleaned generated files."

# Remove Docker test image
clean-docker:
	docker rmi dotfiles-test 2>/dev/null || true
	@echo "Removed Docker test image."

# Stow all dotfiles
stow-all:
	./stow-select.sh

# Unstow all dotfiles
unstow-all:
	@for dir in */; do \
		case "$$dir" in \
			restore/|scripts/|state/|logs/|tests/|.git/|vm/) continue ;; \
			*) stow -D "$${dir%/}" 2>/dev/null || true ;; \
		esac \
	done
	@echo "Unstowed all packages."

# -----------------------------------------------------
# VM Testing Targets
# -----------------------------------------------------
# These targets provide a full VM-based testing environment for visual
# verification of the dotfiles restoration (Hyprland, Waybar, etc.)

# Install VM host dependencies (libvirt, QEMU, etc.)
vm-setup:
	./vm/setup-vm-host.sh

# Download latest Arch Linux ISO
vm-download-iso:
	@echo "Downloading latest Arch Linux ISO..."
	@mkdir -p vm
	@curl -L -o vm/archlinux.iso \
		"https://geo.mirror.pkgbuild.com/iso/latest/archlinux-x86_64.iso"
	@echo "Downloaded to vm/archlinux.iso"

# Create the test VM (interactive - requires Arch installation)
vm-create:
	./vm/create-vm.sh

# Start the VM
vm-start:
	./vm/vm-control.sh start

# Stop the VM gracefully
vm-stop:
	./vm/vm-control.sh stop

# Open VM console in virt-manager
vm-console:
	./vm/vm-control.sh console

# SSH into the VM
vm-ssh:
	./vm/vm-control.sh ssh

# Create a snapshot of the current VM state
vm-snapshot:
	./vm/vm-control.sh snapshot

# Reset VM to clean snapshot
vm-reset:
	./vm/vm-control.sh reset

# Run restore.sh inside the VM
vm-restore:
	./vm/vm-control.sh restore

# Reboot the VM
vm-reboot:
	./vm/vm-control.sh reboot

# Show VM status
vm-status:
	./vm/vm-control.sh status
