# Zera

A beautiful, modern Arch Linux + Hyprland installer.

![Hyprland](https://img.shields.io/badge/Hyprland-Ready-blue)
![Arch Linux](https://img.shields.io/badge/Arch%20Linux-Only-1793D1)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

- **One-liner installation** - Get a complete Hyprland setup in minutes
- **Dynamic theming** - Matugen-powered colors from your wallpaper
- **Curated packages** - Choose minimal, recommended, or full package sets
- **Modular configs** - Easy to customize and extend
- **GPU auto-detection** - NVIDIA, AMD, and Intel support

## Quick Start

### Install from AUR (Recommended)

```bash
yay -S zera
zera install
```

Updates come through pacman:
```bash
yay -Syu        # Updates zera and configs
zera sync       # Re-apply configs after update
```

### One-liner Install

```bash
curl -sL https://raw.githubusercontent.com/maxwell/zera/main/boot.sh | bash
```

### Manual Install

```bash
git clone https://github.com/maxwell/zera ~/.local/share/zera
cd ~/.local/share/zera
./install.sh
```

## What's Included

### Core Components

| Component | Package | Description |
|-----------|---------|-------------|
| Window Manager | Hyprland | Tiling Wayland compositor |
| Bar | Waybar | Highly customizable status bar |
| Terminal | Kitty | GPU-accelerated terminal |
| Shell | Fish + Starship | Modern shell with custom prompt |
| Launcher | Wofi/Walker | Application launcher |
| Notifications | Dunst | Notification daemon |
| Display Manager | SDDM | Login manager with custom theme |

### Theming

Zera uses [Matugen](https://github.com/InioX/matugen) for dynamic color generation:

```bash
# Change theme based on wallpaper
change-theme ~/Pictures/wallpaper.jpg
```

This updates colors for:
- Hyprland borders and gaps
- Waybar
- Kitty terminal
- GTK applications
- And more

## Package Tiers

| Tier | Description |
|------|-------------|
| `minimal` | Just Hyprland and essential tools |
| `recommended` | Minimal + common apps (browser, better CLI tools) |
| `full` | Recommended + optional extras (gaming, dev tools, etc.) |

Select your tier during installation or with flags:

```bash
./install.sh --minimal
./install.sh --full
```

## Optional Features

During installation, you can enable:

- **Gaming** - Steam, Lutris, Gamemode, MangoHud
- **Development** - Docker, various languages
- **Multimedia** - OBS, GIMP, Kdenlive
- **Office** - LibreOffice

## The `zera` Command

When installed via AUR, you get the `zera` command:

```bash
zera                  # Run installer (interactive)
zera install          # Same as above
zera sync             # Re-stow configs (use after updates)
zera status           # Show what's installed/stowed
zera eject hyprland   # Copy config locally for customization
zera theme wall.jpg   # Change color theme
zera help             # Show all commands
```

### Customizing Configs

By default, configs are symlinked from the package. To customize:

```bash
# "Eject" a config to make it local
zera eject hyprland

# Now ~/.config/hypr/ contains real files you can edit
# Future zera updates won't overwrite your changes
```

## Directory Structure

```
zera/
├── bin/zera          # Main command (installed to /usr/bin/)
├── boot.sh           # Curl target for one-liner install
├── install.sh        # Main installer
├── install/          # Modular install scripts
├── defaults/         # Package lists
├── config/           # Dotfiles (stow packages)
├── docs/             # Documentation
└── aur/              # AUR package files
```

## Customization

### Fork and Personalize

1. Fork this repository
2. Edit package lists in `defaults/`
3. Modify configs in `config/`
4. Update `ZERA_REPO` in `boot.sh`

### Package Lists

Edit files in `defaults/`:

- `packages-core.txt` - Essential packages
- `packages-recommended.txt` - Common tools
- `packages-optional.txt` - Feature packages
- `packages-aur.txt` - AUR packages

### Dotfiles

Configs use GNU Stow. Each directory in `config/` is a package:

```
config/
├── hyprland/    # Hyprland config
├── waybar/      # Waybar config
├── kitty/       # Kitty config
└── ...
```

To modify, edit files in these directories and re-run:

```bash
cd ~/.local/share/zera/config
stow --target=$HOME --restow hyprland
```

## Post-Installation

After installation, you'll need to manually:

1. **Restore SSH keys** to `~/.ssh/`
2. **Restore GPG keys** with `gpg --import`
3. **Log in to applications** (browser, Slack, Discord, etc.)
4. **Re-pair Bluetooth devices**

See `docs/MANUAL_STEPS.md` for the full checklist.

## Troubleshooting

### Installation fails

```bash
# Run with dry-run to see what would happen
./install.sh --dry-run
```

### Theme not applying

```bash
# Regenerate theme
matugen image ~/.config/wallpapers/your-wallpaper.jpg
```

### Missing packages

```bash
# Install from defaults
sudo pacman -S --needed $(cat defaults/packages-core.txt | grep -v '^#')
```

## Requirements

- Arch Linux (fresh install recommended)
- Internet connection
- Sudo access

## License

MIT License - see [LICENSE](LICENSE)

## Credits

Inspired by [Omarchy](https://github.com/basecamp/omarchy) by DHH.

## Contributing

Contributions welcome! Please read the contributing guidelines first.
