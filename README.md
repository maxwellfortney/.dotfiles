# Dotfiles

Personal dotfiles and disaster recovery system for Arch Linux with Hyprland.

**Never spend days recovering from a system failure again.** This repo tracks your entire system state and can restore everything with a single command.

## Quick Start

### Fresh Install (Disaster Recovery)

```bash
git clone https://github.com/yourusername/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./scripts/install-deps.sh
./restore/restore.sh
```

### Existing System (Enable Tracking)

```bash
git clone https://github.com/yourusername/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./scripts/capture-state.sh      # Capture current state
./scripts/setup-auto-sync.sh    # Auto-sync every 6 hours
```

## What Gets Tracked

| Category | What's Captured |
|----------|-----------------|
| **Packages** | All pacman and AUR packages |
| **Services** | Enabled systemd services and timers |
| **System** | mkinitcpio, sysctl, kernel params |
| **Config** | Hostname, locale, timezone, user groups |
| **Dotfiles** | All application configs (see below) |

## Dotfiles Packages

| Package | Description |
|---------|-------------|
| `bash` | Bash shell configuration |
| `bin` | Custom scripts (`change-theme`) |
| `desktop-entries` | Application `.desktop` files |
| `dunst` | Notification daemon |
| `electron-flags` | Electron Wayland flags |
| `fish` | Fish shell + starship prompt |
| `fonts` | Geist font family |
| `git` | Git configuration |
| `hyprland` | Window manager config |
| `kitty` | Terminal emulator |
| `matugen` | Material color templates |
| `sddm` | Display manager theme |
| `walker` | Application launcher |
| `wallpapers` | Wallpaper files |
| `waybar` | Status bar |

## Usage

All operations are available via `make`:

```bash
make help              # Show all available commands

# State Management
make capture           # Capture current system state
make sync              # Capture + auto-commit changes

# Restoration
make install-dry-run   # Preview what would be restored
make install           # Full system restoration

# Testing
make test-docker       # Run tests in Docker (safe)
make lint              # Run shellcheck on scripts

# Setup
make setup-auto-sync   # Enable automatic state sync
make stow-all          # Symlink all dotfiles
```

## Repository Structure

```
~/.dotfiles/
├── restore/                    # Restoration scripts
│   ├── restore.sh              # Main orchestrator
│   ├── restore-packages.sh     # Package installation
│   ├── restore-services.sh     # Service enabling
│   ├── restore-system.sh       # System configuration
│   ├── restore-dotfiles.sh     # Dotfiles stowing
│   └── restore-manual.md       # Manual steps checklist
├── scripts/                    # Utility scripts
│   ├── capture-state.sh        # Capture system state
│   ├── sync-state.sh           # Auto-commit wrapper
│   ├── setup-auto-sync.sh      # Install cron job
│   └── install-deps.sh         # Bootstrap dependencies
├── state/                      # Captured state (committed)
│   ├── packages-pacman.txt
│   ├── packages-aur.txt
│   ├── services-enabled.txt
│   └── ...
├── tests/                      # Test infrastructure
│   ├── Dockerfile
│   └── test-runner.sh
├── [dotfile packages]/         # Stow packages (bash, fish, hyprland, etc.)
├── Makefile                    # Build automation
└── stow-select.sh              # Interactive stow helper
```

## Automatic State Sync

Enable automatic tracking of system changes:

```bash
./scripts/setup-auto-sync.sh
```

This installs a cron job that runs every 6 hours:
- Captures current system state
- Commits changes to git (if any)
- Logs to `~/.dotfiles/logs/sync-state.log`

To also auto-push to remote:
```bash
export DOTFILES_AUTO_PUSH=true
```

## Restoration Options

```bash
# Full restoration
./restore/restore.sh

# Preview only (no changes)
./restore/restore.sh --dry-run

# Skip specific steps
./restore/restore.sh --skip-packages
./restore/restore.sh --skip-services
./restore/restore.sh --skip-system
./restore/restore.sh --skip-dotfiles

# Run individual modules
./restore/restore-packages.sh
./restore/restore-services.sh
./restore/restore-system.sh
./restore/restore-dotfiles.sh
```

## Manual Steps

Some things cannot be automated. After restoration, complete these manually:

- **SSH Keys** - Restore from backup, set permissions
- **GPG Keys** - Import and trust
- **Application Logins** - Slack, Discord, browsers, etc.
- **Bluetooth Devices** - Re-pair devices
- **Secrets File** - Copy `99-secrets.fish.example` to `99-secrets.fish`

See [`restore/restore-manual.md`](restore/restore-manual.md) for the complete checklist.

## Testing

Run the test suite in Docker (safe, won't touch your system):

```bash
make test-docker
```

Tests include:
- ShellCheck static analysis
- Script existence and permissions
- State capture validation
- Restore dry-run
- Idempotency checks

## Theming

Uses [matugen](https://github.com/InioX/matugen) for automatic material color scheme generation from wallpapers.

```bash
change-theme ~/Pictures/wallpaper.jpg
```

Generates colors for: Hyprland, Kitty, GTK, Qt, Walker, Brave, Slack, Spotify.

## Stow Usage

Individual package management:

```bash
stow fish              # Symlink fish config
stow -D fish           # Remove fish symlinks
./stow-select.sh       # Interactive selection
./stow-select.sh --force   # Replace existing configs
./stow-select.sh --adopt   # Adopt existing configs into repo
```

## Design Principles

- **Idempotent** - All scripts are safe to run multiple times
- **Modular** - Run individual restoration steps as needed
- **Automatic** - State syncs every 6 hours via cron
- **Tested** - Docker-based test suite validates everything
- **Documented** - Manual steps clearly listed

## License

MIT
