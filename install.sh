#!/bin/bash
#
# Arch-X — Automated Arch Linux + Hyprland environment setup
#
# Usage:
#   git clone <repo> ~/Arch-X && cd ~/Arch-X && ./install.sh
#
# Assumes: fresh Arch Linux install with a non-root user and sudo access.

set -eo pipefail
source "$(dirname "$0")/lib/common.sh"
sudo_keepalive

echo ""
echo "  ╔══════════════════════════════════════╗"
echo "  ║         Arch-X Environment Setup     ║"
echo "  ╚══════════════════════════════════════╝"
echo ""

# ─── [1/10] Packages ─────────────────────────────────

step "1/10" "Installing packages..."

install_packages
setup_gpu

# AUR packages (requires yay)
if ! install_aur_packages; then
    warn "yay not found — installing yay first..."
    sudo pacman -S --needed --noconfirm base-devel
    git clone https://aur.archlinux.org/yay.git /tmp/yay-install
    (cd /tmp/yay-install && makepkg -si --noconfirm)
    rm -rf /tmp/yay-install
    install_aur_packages
fi

# ─── [2/10] Symlink configs ──────────────────────────

step "2/10" "Linking configuration files..."

mkdir -p "$HOME/.config"

for dir in hypr waybar ghostty wofi ags wlogout nvim gtk-3.0 gtk-4.0; do
    if [ -e "$HOME/.config/$dir" ] && [ ! -L "$HOME/.config/$dir" ]; then
        mv "$HOME/.config/$dir" "$HOME/.config/${dir}.bak"
        warn "Backed up existing ~/.config/$dir → ${dir}.bak"
    fi
    ln -sfn "$DOTDIR/$dir" "$HOME/.config/$dir"
    info "~/.config/$dir → $DOTDIR/$dir"
done

# .zshrc
if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
    mv "$HOME/.zshrc" "$HOME/.zshrc.bak"
    warn "Backed up existing ~/.zshrc → .zshrc.bak"
fi
ln -sf "$DOTDIR/.zshrc" "$HOME/.zshrc"
info "~/.zshrc → $DOTDIR/.zshrc"

# SSH config — copy (don't symlink, user will add hosts)
mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
if [ ! -f "$HOME/.ssh/config" ]; then
    cp "$DOTDIR/ssh/config" "$HOME/.ssh/config"
    chmod 600 "$HOME/.ssh/config"
    info "~/.ssh/config created from template"
else
    info "~/.ssh/config already exists — skipping"
fi

# GPG agent config
mkdir -p "$HOME/.gnupg" && chmod 700 "$HOME/.gnupg"
ln -sf "$DOTDIR/gnupg/gpg-agent.conf" "$HOME/.gnupg/gpg-agent.conf"
info "~/.gnupg/gpg-agent.conf → $DOTDIR/gnupg/gpg-agent.conf"

# Wallpaper — fetch from Wallhaven if none exists
mkdir -p "$HOME/Pictures"
if [ ! -f "$HOME/Pictures/wallpaper.jpg" ]; then
    info "Fetching cyberpunk wallpaper from Wallhaven..."
    if fetch_wallpaper "cyberpunk" "$HOME/Pictures/wallpaper.jpg" "2560x1440"; then
        info "Wallpaper saved to ~/Pictures/wallpaper.jpg"
    else
        warn "Could not fetch wallpaper — set one manually in ~/.config/hypr/hyprpaper.conf"
    fi
else
    info "~/Pictures/wallpaper.jpg already exists"
fi

# ─── [3/10] Default shell ────────────────────────────

step "3/10" "Setting zsh as default shell..."

if [ "$SHELL" != "/usr/bin/zsh" ]; then
    chsh -s /usr/bin/zsh
    info "Default shell changed to zsh"
else
    info "Already using zsh"
fi

# ─── [4/10] SSH agent ────────────────────────────────

step "4/10" "Enabling SSH agent..."

systemctl --user enable --now ssh-agent.socket 2>/dev/null || \
    systemctl --user enable --now ssh-agent 2>/dev/null || \
    warn "Could not enable ssh-agent service — enable manually after reboot"

grep -rl "PRIVATE KEY" ~/.ssh/ 2>/dev/null | xargs -r ssh-add 2>/dev/null || true
info "SSH agent configured"

# ─── [5/10] Docker ───────────────────────────────────

step "5/10" "Enabling Docker..."

sudo systemctl enable --now docker
if ! groups "$USER" | grep -q docker; then
    sudo usermod -aG docker "$USER"
    info "Added $USER to docker group (takes effect after re-login)"
else
    info "Already in docker group"
fi

# ─── [6/10] Bluetooth ────────────────────────────────

step "6/10" "Enabling Bluetooth..."

sudo systemctl enable --now bluetooth.service 2>/dev/null && \
    info "Bluetooth service enabled" || \
    warn "Could not enable bluetooth — no adapter detected?"

# ─── [7/10] SDDM display manager ────────────────────

step "7/10" "Setting up SDDM..."

install_sddm_theme

# Disable competing display managers
sudo systemctl disable gdm 2>/dev/null || true
sudo systemctl disable lightdm 2>/dev/null || true
sudo systemctl enable sddm
info "SDDM enabled — will start on next boot"

# ─── [8/10] GTK theme ────────────────────────────────

step "8/10" "Applying GTK theme..."

gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' 2>/dev/null || \
    warn "gsettings not available — GTK theme will apply from settings.ini on first Hyprland session"
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
info "GTK theme set to adw-gtk3-dark"

# ─── [9/10] Permissions + plugins ────────────────────

step "9/10" "Setting permissions and installing plugins..."

chmod +x "$DOTDIR/waybar/scripts/"*.sh 2>/dev/null || true
chmod +x "$DOTDIR/bin/"* 2>/dev/null || true
info "Scripts marked executable"

nvim --headless "+Lazy! sync" +qa 2>/dev/null || \
    warn "Neovim plugin sync skipped — run 'nvim' to install plugins on first launch"

# Hyprland plugins (hyprexpo for workspace overview)
if command -v hyprpm &>/dev/null; then
    hyprpm update 2>/dev/null || true
    hyprpm add https://github.com/hyprwm/hyprland-plugins 2>/dev/null || true
    hyprpm enable hyprexpo 2>/dev/null && info "hyprexpo plugin enabled" || \
        warn "hyprexpo install failed — run 'hyprpm add https://github.com/hyprwm/hyprland-plugins && hyprpm enable hyprexpo' manually"
else
    warn "hyprpm not found — hyprexpo plugin skipped"
fi

# ─── [10/10] Summary ─────────────────────────────────

step "10/10" "Setup complete!"

echo ""
echo "  ┌──────────────────────────────────────┐"
echo "  │  Reboot to start Hyprland via SDDM   │"
echo "  └──────────────────────────────────────┘"
echo ""
echo "  After reboot, set up password manager:"
echo ""
echo "    gpg --full-generate-key"
echo "    pass init <your-gpg-id>"
echo "    pass git init"
echo ""
echo "  Change wallpaper anytime:"
echo "    fetch-wallpaper                  # random cyberpunk"
echo "    fetch-wallpaper 'neon city'      # custom search"
echo "    fetch-wallpaper 'synthwave'      # retro-futuristic"
echo ""
echo "  Keybindings:"
echo "    Super+Return    Ghostty terminal"
echo "    Super+D         Wofi launcher"
echo "    Super+M         Maximize toggle"
echo "    Super+F         Fullscreen toggle"
echo "    Super+Q         Close window"
echo "    Super+V         Clipboard history"
echo "    Super+B         Bluetooth manager"
echo "    Super+N         Notification history"
echo "    Super+K         Lock screen"
echo "    Print           Screenshot (full → clipboard)"
echo "    Shift+Print     Screenshot (region → clipboard)"
echo "    Ctrl+R          Fuzzy history search"
echo "    sshs            SSH host picker"
echo "    z <dir>         Smart cd (zoxide)"
echo ""
