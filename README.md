# Arch-X

Minimal Arch Linux + Hyprland development environment. One script to go from a fresh Arch install to a fully configured, keyboard-driven desktop.

## What you get

**Desktop**
- Hyprland (tiling Wayland compositor)
- Waybar (status bar with CPU, memory, network, battery, keyboard layout)
- Dunst (notifications — left-click to open, right-click to dismiss)
- Wofi (app launcher)
- Wlogout (power menu)
- Hyprlock (lock screen)
- adw-gtk3-dark theme

**Terminal & Shell**
- Ghostty terminal
- Zsh with autosuggestions, syntax highlighting, fzf integration
- Ctrl+R fuzzy history, Ctrl+T file finder, Alt+C directory jumper
- Zoxide (smart cd), bat (syntax-highlighted cat), eza (modern ls)
- Neovim (NvChad config with lazy.nvim)

**SSH Management**
- `s` — interactive SSH host picker (fzf + ~/.ssh/config)
- `ssh-deploy-key <label> <user> <ip>` — generate and deploy SSH key in one command
- `mount-ssh <host>` — mount remote filesystem via SSHFS, opens yazi
- ssh-agent with systemd, auto-loads keys

**Security**
- pass (GPG-based password manager, unlock once per session)
- GPG agent with 8-hour cache
- Unified Kernel Image support

**Dev Tools**
- Docker, lazygit, ripgrep, fd, yazi (file manager)
- Git aliases (gs, ga, gc, gd, gl, gp, gpl)

**Keyboard Layouts**
- US, Russian, Armenian (phonetic)
- Alt+Shift to switch, indicator in waybar

## Installation

### 1. Install Arch Linux

Boot the Arch ISO and run:

```bash
archinstall
```

Recommended settings:
- **Disk**: ext4, full disk
- **Profile**: Minimal (no desktop)
- **Audio**: Pipewire
- **Bootloader**: systemd-boot (with Unified Kernel Images)
- **Network**: NetworkManager
- **Swap**: zram with zstd compression

Create a user with sudo access. Reboot.

### 2. Connect to network

```bash
# WiFi
nmcli device wifi connect "SSID" password "PASSWORD"

# Or ethernet (should auto-connect)
nmcli device status
```

### 3. Install Arch-X

```bash
sudo pacman -S git
git clone https://github.com/whitebyte0/Arch-X.git ~/Arch-X
cd ~/Arch-X && ./install.sh
```

The script will ask for your password once, then handle everything:
- Installs all packages (pacman + yay for AUR)
- Symlinks all configs to `~/.config/`
- Sets zsh as default shell
- Enables ssh-agent, Docker
- Applies GTK dark theme
- Installs Neovim plugins

### 4. Reboot

```bash
reboot
```

Log in on TTY1 — Hyprland starts automatically.

### 5. Post-install (manual)

Set up the password manager:

```bash
gpg --full-generate-key
pass init <your-gpg-id>
pass git init
```

## Updating

After making changes to the repo:

```bash
cd ~/Arch-X && git pull && ./update.sh
```

This syncs packages, verifies symlinks, and reloads Hyprland, Waybar, and Dunst live — no reboot needed.

## Keybindings

| Key | Action |
|-----|--------|
| Super+Return | Ghostty terminal |
| Super+D | Wofi launcher |
| Super+Q | Close window |
| Super+M | Maximize toggle |
| Super+F | Fullscreen toggle |
| Super+Space | Toggle floating |
| Super+K | Lock screen |
| Super+Arrows | Move focus |
| Super+Shift+Arrows | Move window |
| Super+1-5 | Switch workspace |
| Super+Shift+1-5 | Move window to workspace |
| Super+S | Screen record (full) |
| Super+E | Screen record (region) |
| Alt+Shift | Switch keyboard layout |
| Ctrl+R | Fuzzy history search |
| Ctrl+T | Fuzzy file finder |
| Alt+C | Fuzzy directory jump |

## Structure

```
~/Arch-X/
├── install.sh          # Fresh install setup
├── update.sh           # Update existing install
├── .zshrc              # Shell config
├── .zprofile           # Auto-start Hyprland
├── hypr/               # Hyprland + Hyprlock
├── waybar/             # Status bar + scripts
├── ghostty/            # Terminal
├── wofi/               # App launcher
├── dunst/              # Notifications
├── wlogout/            # Power menu
├── nvim/               # Neovim (NvChad)
├── gtk-3.0/            # GTK3 theme settings
├── gtk-4.0/            # GTK4 theme settings
├── gnupg/              # GPG agent config
└── ssh/                # SSH config template
```