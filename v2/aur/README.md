# Zera AUR Package

This directory contains the files needed to submit Zera to the AUR.

## Publishing to AUR

### First Time Setup

1. Create an AUR account at https://aur.archlinux.org
2. Add your SSH key to your AUR account
3. Clone the AUR package base:
   ```bash
   git clone ssh://aur@aur.archlinux.org/zera.git aur-zera
   cd aur-zera
   ```

### Publishing a Release

1. Update version in these files:
   - `/v2/version`
   - `/v2/aur/PKGBUILD` (pkgver)
   - `/v2/aur/.SRCINFO` (pkgver and source URL)

2. Create a GitHub release with tag `v0.1.0` (or your version)

3. Get the sha256sum of the release tarball:
   ```bash
   curl -sL https://github.com/maxwell/zera/archive/v0.1.0.tar.gz | sha256sum
   ```

4. Update `sha256sums` in PKGBUILD and .SRCINFO

5. Regenerate .SRCINFO (or use the template):
   ```bash
   makepkg --printsrcinfo > .SRCINFO
   ```

6. Copy files to AUR repo and push:
   ```bash
   cp PKGBUILD .SRCINFO ~/aur-zera/
   cd ~/aur-zera
   git add PKGBUILD .SRCINFO
   git commit -m "Update to v0.1.0"
   git push
   ```

## Testing Locally

Build and install the package locally:

```bash
cd /path/to/v2
makepkg -si
```

Or test the PKGBUILD:

```bash
cd aur
makepkg -f
```

## Package Structure

When installed, Zera is laid out as:

```
/usr/bin/zera                    # Main command
/usr/share/zera/
├── install/                     # Install scripts
├── config/                      # Stow packages (dotfiles)
├── defaults/                    # Package lists
├── docs/                        # Documentation
└── version                      # Version file
/usr/share/licenses/zera/LICENSE # License
```

## User Workflow

```bash
# Install
yay -S zera

# Run installer (first time)
zera install

# After package update, re-sync configs
zera sync

# Customize a config (eject from package management)
zera eject hyprland

# Change theme
zera theme ~/Pictures/wallpaper.jpg
```
