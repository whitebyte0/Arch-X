# Arch-X

Minimal Arch Linux + Hyprland development environment. One script to go from a fresh Arch install to a fully configured, keyboard-driven desktop.

## What you get

**Desktop**
- Hyprland (tiling Wayland compositor)
- Waybar (status bar with CPU, memory, network, bluetooth, battery, keyboard layout)
- AGS notification center (bottom bar + sidebar history, DND, action buttons)
- Wofi (app launcher)
- Wlogout (power menu)
- Hyprlock + Hypridle (lock screen + auto-lock/suspend)
- Hyprpaper (wallpaper)
- SDDM (display manager with custom theme)
- adw-gtk3-dark theme

**Terminal & Shell**
- Ghostty terminal
- Zsh with autosuggestions, syntax highlighting, fzf integration
- Ctrl+R fuzzy history, Ctrl+T file finder, Alt+C directory jumper
- Zoxide (smart cd), bat (syntax-highlighted cat), eza (modern ls)
- Yazi (keyboard-driven file manager with SSHFS support)

**Editor (Neovim)**
- NvChad base config with lazy.nvim
- LSP support: Go, Rust, TypeScript, JavaScript, PHP, HTML, CSS, JSON, YAML, Bash, Docker
- Mason for automatic LSP/formatter installation
- Treesitter syntax highlighting for all languages
- Format on save (gofmt, rustfmt, prettier, php_cs_fixer)
- render-markdown.nvim (inline markdown rendering)
- todo-comments.nvim (highlight TODO, FIXME, HACK, BUG)
- trouble.nvim (diagnostics panel)
- which-key.nvim (keybinding hints popup)
- gitsigns.nvim (git diff in gutter)
- nvim-autopairs, nvim-surround, Comment.nvim

**SSH Management**
- `sshs` — interactive SSH host picker (TUI)
- `setup-deploy-sshkey <label> <user> <ip>` — generate and deploy SSH key in one command
- `mount-ssh <host>` — mount remote filesystem via SSHFS, opens yazi
- `umount-ssh <host>` — unmount remote filesystem (`--all` to unmount all)
- `setup-deploy-server <host> [port]` — provision a fresh Ubuntu VPS for deployment (tested on Ubuntu 22.04 LTS). Auto-rolls back on failure
- ssh-agent with systemd, auto-loads keys

**Security**
- pass (GPG-based password manager, unlock once per session)
- GPG agent with 8-hour cache
- Unified Kernel Image support

**Dev Tools**
- Docker, lazygit, ripgrep, fd, yazi (file manager)
- glab (GitLab CLI), gh (GitHub CLI)
- Git aliases (gs, ga, gc, gd, gl, gp, gpl)
- Clipboard history (Super+V)
- `notif` — notification mode switcher (reserved/dynamic/overlay), DND, history clear

**Hardware**
- GPU auto-detection (NVIDIA, AMD, Intel)
- Bluetooth (bluez + bluetuith TUI + waybar module)
- Volume, brightness, and media keys
- Multi-monitor support with interactive setup
- Keyboard layouts: US, Russian, Armenian (phonetic)

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

The script asks for your password once, then handles everything:
- Installs all packages (pacman + yay for AUR)
- Symlinks all configs to `~/.config/`
- Sets zsh as default shell
- Enables ssh-agent, Docker, Bluetooth
- Sets up SDDM display manager with custom theme
- Applies GTK dark theme
- Installs Neovim plugins and LSP servers

### 4. Reboot

```bash
reboot
```

SDDM greets you at login. Select Hyprland and log in.

### 5. Post-install

Set up the password manager:

```bash
gpg --full-generate-key
pass init <your-gpg-id>
pass git init
```

Change wallpaper (fetches from [Wallhaven](https://wallhaven.cc)):

```bash
fetch-wallpaper                     # random cyberpunk
fetch-wallpaper "neon city"         # custom search
fetch-wallpaper "synthwave" 3840x2160  # custom resolution
```

## Updating

After making changes to the repo:

```bash
cd ~/Arch-X && git pull && ./update.sh
```

This syncs packages, verifies symlinks, updates SDDM theme, and reloads Hyprland, Waybar, and AGS live — no reboot needed.

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
| Super+V | Clipboard history |
| Super+Shift+V | Delete clipboard entry |
| Super+B | Bluetooth manager |
| Super+N | Notification sidebar (history, actions, DND) |
| Super+Shift+N | Dismiss current notification |
| Super+Arrows | Move focus |
| Super+Shift+Arrows | Move window |
| Super+Alt+Arrows | Resize window |
| Super+1-0 | Switch workspace (1-10) |
| Super+Shift+1-0 | Move window to workspace |
| Print | Screenshot (full screen → clipboard) |
| Shift+Print | Screenshot (region → clipboard) |
| Super+Print | Screenshot (region → file) |
| Super+S | Screen record (full) |
| Super+E | Screen record (region) |
| XF86Audio keys | Volume up/down/mute |
| XF86Brightness keys | Brightness up/down |
| XF86AudioPlay/Next/Prev | Media controls |
| Alt+Shift | Switch keyboard layout |
| Ctrl+R | Fuzzy history search |
| Ctrl+T | Fuzzy file finder |
| Alt+C | Fuzzy directory jump |

## Neovim

LSP servers are installed automatically via Mason on first launch. Run `:Mason` to manage them.

| Key | Action |
|-----|--------|
| gd | Go to definition |
| K | Hover info |
| gcc | Toggle comment |
| cs"' | Change surrounding `"` to `'` |
| :Trouble | Open diagnostics panel |
| :TodoTelescope | Search TODO/FIXME comments |

## Structure

```
~/Arch-X/
├── install.sh          # Fresh install setup
├── update.sh           # Update existing install
├── packages.txt        # Pacman packages (one per line)
├── packages-aur.txt    # AUR packages (one per line)
├── lib/
│   └── common.sh       # Shared functions (GPU, packages, logging)
├── .zshrc              # Shell config
├── hypr/               # Hyprland + Hyprlock + Hypridle + Hyprpaper
├── waybar/             # Status bar + scripts
├── ghostty/            # Terminal
├── wofi/               # App launcher
├── ags/                # Notification center (AGS — bottom bar + sidebar)
├── wlogout/            # Power menu
├── nvim/               # Neovim (NvChad + plugins)
├── gtk-3.0/            # GTK3 theme settings
├── gtk-4.0/            # GTK4 theme settings
├── gnupg/              # GPG agent config
├── ssh/                # SSH config template
├── sddm/               # SDDM display manager config
├── sddm-theme/         # Custom SDDM login theme
└── bin/                # CLI tools (setup-deploy-sshkey, mount-ssh, fetch-wallpaper, etc.)
```
