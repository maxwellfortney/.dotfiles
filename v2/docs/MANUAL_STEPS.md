# Manual Steps

These steps require manual intervention after installation.
Complete them after the installer finishes.

## Priority: High (Do First)

### SSH Keys

- [ ] Restore SSH keys from backup to `~/.ssh/`
- [ ] Set correct permissions:
  ```bash
  chmod 700 ~/.ssh
  chmod 600 ~/.ssh/*
  chmod 644 ~/.ssh/*.pub
  ```
- [ ] Add SSH key to ssh-agent:
  ```bash
  ssh-add ~/.ssh/id_ed25519
  ```
- [ ] Test GitHub connection:
  ```bash
  ssh -T git@github.com
  ```

### GPG Keys

- [ ] Restore GPG keys from backup
- [ ] Import keys:
  ```bash
  gpg --import private-key.asc
  ```
- [ ] Trust keys:
  ```bash
  gpg --edit-key <key-id>
  # Then type: trust
  ```
- [ ] Set Git to use GPG:
  ```bash
  git config --global user.signingkey <key-id>
  ```

### Secrets File

- [ ] Copy fish secrets template:
  ```bash
  cp ~/.config/fish/conf.d/99-secrets.fish.example ~/.config/fish/conf.d/99-secrets.fish
  ```
- [ ] Edit and add your actual tokens (NPM_TOKEN, etc.)

## Priority: Medium

### Browser (Brave)

- [ ] Log in to Brave sync to restore bookmarks, passwords, extensions
- [ ] Or restore browser profile from backup
- [ ] Apply matugen theme if desired

### Application Logins

- [ ] **Slack** - Log in to workspaces
- [ ] **Discord** - Log in to account
- [ ] **Spotify** - Log in (for Spicetify theming, restore cookies)
- [ ] **VS Code / Cursor** - Log in for settings sync
- [ ] **1Password / Password Manager** - Log in

### Development Tools (if using development feature)

- [ ] **Docker** - Log in: `docker login`
- [ ] **Node.js** - Install via asdf: `asdf install nodejs latest`
- [ ] **Python** - Install via asdf or pyenv
- [ ] **Rust** - Already installed? Verify with `rustc --version`

## Priority: Low

### Bluetooth

- [ ] Re-pair all Bluetooth devices
- [ ] Note: Bluetooth pairings don't persist across installs

### Cloud Storage

- [ ] Log in to cloud storage services (Dropbox, Google Drive, etc.)
- [ ] Sync important folders

### VPN

- [ ] Import VPN configurations
- [ ] Log in to VPN services

### Gaming (if using gaming feature)

- [ ] Log in to Steam
- [ ] Restore game saves from backup

## Theme Configuration

### Set Your Theme

```bash
# List available wallpapers
ls ~/.config/wallpapers/

# Apply theme from wallpaper
change-theme ~/.config/wallpapers/your-wallpaper.jpg
```

### Manual Theme Regeneration

If colors don't look right:

```bash
# Regenerate with matugen directly
matugen image ~/.config/wallpapers/your-wallpaper.jpg

# Restart Hyprland to apply
hyprctl reload
```

## Verification Checklist

After completing the above, verify:

- [ ] Can push/pull from GitHub (SSH works)
- [ ] GPG signing works for commits
- [ ] All applications open correctly
- [ ] Hyprland keybinds work (Super+Q for terminal, Super+E for file manager)
- [ ] Waybar displays correctly
- [ ] Notifications work (test with `notify-send "Test"`)
- [ ] Application launcher works (Super+Space)
- [ ] Theme/colors are correct

## Backup Recommendations

To make future installations easier, regularly backup:

1. **SSH Keys**: `~/.ssh/` (store encrypted!)
2. **GPG Keys**: Export with `gpg --export-secret-keys -a > private-keys.asc`
3. **Browser Profile**: `~/.config/BraveSoftware/` or use browser sync
4. **Password Manager**: Ensure cloud sync is enabled
5. **Dotfiles**: Keep this repo updated!

### Suggested Backup Locations

- External encrypted drive
- Cloud storage (encrypted)
- Separate git repo for secrets (private, encrypted)

## Notes

- Some changes require logout/login to take effect
- Some changes require a full reboot
- If something isn't working, check the installation output for errors
