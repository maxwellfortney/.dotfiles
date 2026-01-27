# Manual Restoration Steps

These steps require manual intervention and cannot be fully automated.
Complete them after running the automated restoration scripts.

## Priority: High (Do First)

### SSH Keys

- [ ] Restore SSH keys from backup to `~/.ssh/`
- [ ] Set correct permissions: `chmod 700 ~/.ssh && chmod 600 ~/.ssh/*`
- [ ] Add SSH key to ssh-agent: `ssh-add ~/.ssh/id_ed25519`
- [ ] Test GitHub connection: `ssh -T git@github.com`

### GPG Keys

- [ ] Restore GPG keys from backup
- [ ] Import keys: `gpg --import private-key.asc`
- [ ] Trust keys: `gpg --edit-key <key-id>` then `trust`
- [ ] Set Git to use GPG: `git config --global user.signingkey <key-id>`

### Secrets File

- [ ] Copy fish secrets template: `cp ~/.config/fish/conf.d/99-secrets.fish.example ~/.config/fish/conf.d/99-secrets.fish`
- [ ] Edit and add your actual tokens (NPM_TOKEN, etc.)

## Priority: Medium

### Git Configuration

- [ ] Update git remote URL if needed: `git remote set-url origin git@github.com:username/dotfiles.git`
- [ ] Verify git config: `git config --list`

### Browser (Brave)

- [ ] Log in to Brave sync to restore bookmarks, passwords, extensions
- [ ] Or restore browser profile from backup
- [ ] Apply matugen theme if needed

### Application Logins

- [ ] **Slack** - Log in to workspaces
- [ ] **Discord** - Log in to account
- [ ] **Spotify** - Log in (or restore cookies for Spicetify)
- [ ] **VS Code / Cursor** - Log in for settings sync
- [ ] **1Password / Password Manager** - Log in

### Development Tools

- [ ] **Node.js** - Install via asdf: `asdf install nodejs latest`
- [ ] **Python** - Install via asdf or pyenv
- [ ] **Rust** - Install via rustup: `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`
- [ ] **Go** - Install via asdf or pacman
- [ ] **Docker** - Log in: `docker login`

### Databases

- [ ] Restore database dumps if applicable
- [ ] MongoDB Compass - restore connections
- [ ] pgAdmin / DBeaver - restore connections

## Priority: Low

### Cloud Storage

- [ ] Log in to cloud storage services (Dropbox, Google Drive, etc.)
- [ ] Sync important folders

### Email

- [ ] Configure email client if using local client

### VPN

- [ ] Import VPN configurations
- [ ] Log in to VPN services

### Gaming

- [ ] Log in to Steam
- [ ] Restore game saves from backup

### Printers/Scanners

- [ ] Configure printers if needed
- [ ] Install printer drivers

## System Tweaks (If Not Auto-Restored)

### Boot Loader

- [ ] Verify GRUB/systemd-boot configuration
- [ ] Check kernel parameters in `/etc/default/grub` or `/boot/loader/entries/*.conf`

### Display Manager

- [ ] Verify SDDM theme is working
- [ ] If custom SDDM theme not appearing, check `/usr/share/sddm/themes/`

### Audio

- [ ] Verify PipeWire/PulseAudio is working
- [ ] Configure audio devices if needed

### Bluetooth

- [ ] Re-pair Bluetooth devices
- [ ] Bluetooth devices won't auto-pair - need to pair again

### Monitors

- [ ] Verify monitor configuration in Hyprland
- [ ] Adjust `~/.config/hypr/modules/monitors.conf` if needed

## Verification Checklist

After completing the above, verify:

- [ ] Can push/pull from GitHub
- [ ] GPG signing works for commits
- [ ] All applications open correctly
- [ ] Hyprland keybinds work
- [ ] Waybar displays correctly
- [ ] Notifications work (dunst)
- [ ] Application launcher works (walker)
- [ ] Theme/colors are correct (run `change-theme <wallpaper>`)

## Backup Recommendations

To make future restorations easier, regularly backup:

1. **SSH Keys**: `~/.ssh/` (store encrypted!)
2. **GPG Keys**: Export with `gpg --export-secret-keys -a > private-keys.asc`
3. **Browser Profile**: `~/.config/BraveSoftware/` or use browser sync
4. **Password Manager**: Ensure cloud sync is enabled
5. **Application Configs**: Use this dotfiles repo!

### Suggested Backup Locations

- External encrypted drive
- Cloud storage (encrypted)
- Separate git repo for secrets (private, encrypted)

## Notes

- Some changes require logout/login to take effect
- Some changes require a full reboot
- If something isn't working, check the restoration script logs
