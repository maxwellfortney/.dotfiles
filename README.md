# Dotfiles

Personal dotfiles for Linux (Arch-based), managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Overview

This repository contains configuration files for a Hyprland-based desktop environment with material color theming via matugen.

## What's Included

| Package | Description |
|---------|-------------|
| `bash` | Bash shell configuration |
| `bin` | Custom scripts (`change-theme`, `sunshine-*`) |
| `desktop-entries` | Application `.desktop` files |
| `dunst` | Notification daemon configuration |
| `electron-flags` | Electron app flags (Wayland support) |
| `fish` | Fish shell with aliases, completions, and starship prompt |
| `fonts` | Geist font family |
| `git` | Git configuration files |
| `hyprland` | Hyprland window manager (keybinds, animations, window rules, etc.) |
| `kitty` | Kitty terminal emulator |
| `matugen` | Material color scheme generator templates |
| `sddm` | Display manager theme |
| `walker` | Application launcher configuration |
| `wallpapers` | Wallpaper files |
| `waybar` | Status bar configuration |

## Dependencies

- [GNU Stow](https://www.gnu.org/software/stow/) - Symlink farm manager
- [Hyprland](https://hyprland.org/) - Wayland compositor
- [Hyprpaper](https://github.com/hyprwm/hyprpaper) - Wallpaper utility
- [Kitty](https://sw.kovidgoyal.net/kitty/) - Terminal emulator
- [Fish](https://fishshell.com/) - Shell
- [Waybar](https://github.com/Alexays/Waybar) - Status bar
- [Dunst](https://dunst-project.org/) - Notification daemon
- [Walker](https://github.com/abenz1267/walker) - Application launcher
- [Matugen](https://github.com/InioX/matugen) - Material color scheme generator
- [fzf](https://github.com/junegunn/fzf) - Fuzzy finder (optional, for stow helper)

### Arch Linux

```bash
sudo pacman -S stow hyprland hyprpaper kitty fish waybar dunst
yay -S walker-bin matugen-bin
```

## Installation

1. Clone this repository to `~/.dotfiles`:

```bash
git clone https://github.com/yourusername/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

2. Use the interactive stow helper to select packages:

```bash
./stow-select.sh
```

Or stow individual packages manually:

```bash
stow fish        # Stow fish shell config
stow hyprland    # Stow Hyprland config
stow kitty       # Stow kitty config
# etc.
```

3. To stow everything at once:

```bash
stow */
```

4. **Set up secrets file** (if using fish shell):

The fish configuration includes a secrets file that is gitignored. Copy the example file and add your tokens:

```bash
cp ~/.config/fish/conf.d/99-secrets.fish.example ~/.config/fish/conf.d/99-secrets.fish
# Edit 99-secrets.fish and add your actual tokens (e.g., NPM_TOKEN)
```

If the secrets file is missing, you'll see a warning when starting a new fish shell session.

## Unstowing

To remove symlinks for a package:

```bash
stow -D fish     # Remove fish shell config symlinks
```

## Custom Scripts

### `change-theme`

Changes the wallpaper and regenerates the color scheme using matugen:

```bash
change-theme ~/Pictures/wallpaper.jpg
```

### `stow-select.sh`

Interactive script to select which dotfile packages to stow. Uses fzf if available, falls back to whiptail or basic selection.

```bash
./stow-select.sh           # Normal mode
./stow-select.sh --force   # Remove existing files and stow (backs up to ~/.config-backup)
./stow-select.sh --adopt   # Adopt existing files into the repo
```

- `--force` - Backs up conflicting files to `~/.config-backup/` and removes them before stowing. Use this when you want to replace existing configs with the ones from this repo.
- `--adopt` - Moves existing config files into the dotfiles repo and creates symlinks. Use this when you want to bring existing configs into version control.

## Structure

Each top-level directory is a stow package. The internal structure mirrors the target location relative to `$HOME`:

```
package/
└── .config/
    └── app/
        └── config.file
```

When stowed, this creates: `~/.config/app/config.file`

## Theming

This setup uses [matugen](https://github.com/InioX/matugen) for automatic material color scheme generation from wallpapers. Templates in `matugen/.config/matugen/templates/` generate color configs for:

- Hyprland
- Kitty
- GTK
- Kvantum/Qt
- Walker
- Brave browser
- Slack
- Spotify

Run `change-theme <wallpaper>` to update colors across all applications.

## License

MIT
