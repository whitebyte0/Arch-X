#!/bin/bash
#
# Arch-X — Automated Arch Linux + Hyprland environment setup
#
# Usage:
#   git clone <repo> ~/Arch-X && cd ~/Arch-X && ./install.sh
#
# Assumes: fresh Arch Linux install with a non-root user and sudo access.

set -e

DOTDIR="$(cd "$(dirname "$0")" && pwd)"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

step() { echo -e "\n${GREEN}[$1]${NC} $2"; }
warn() { echo -e "${YELLOW}  ⚠ $1${NC}"; }
info() { echo -e "  $1"; }

echo ""
echo "  ╔══════════════════════════════════════╗"
echo "  ║         Arch-X Environment Setup     ║"
echo "  ╚══════════════════════════════════════╝"
echo ""

# ─── [1/10] Packages ─────────────────────────────────

step "1/10" "Installing packages..."

sudo pacman -S --needed --noconfirm \
    hyprland waybar dunst wofi hyprlock grim slurp wf-recorder nwg-look \
    xdg-desktop-portal-hyprland \
    ghostty zsh zsh-autosuggestions zsh-syntax-highlighting \
    fzf fd ripgrep eza bat zoxide yazi sshfs lazygit sshs \
    neovim git docker docker-compose \
    ttf-jetbrains-mono-nerd \
    pass pass-otp wl-clipboard gnupg pinentry \
    openssh sshpass \
    firefox \
    sddm qt6-svg qt6-declarative

# AUR packages (requires yay)
if command -v yay &>/dev/null; then
    yay -S --needed --noconfirm wlogout adw-gtk3
else
    warn "yay not found — installing yay first..."
    sudo pacman -S --needed --noconfirm base-devel
    git clone https://aur.archlinux.org/yay.git /tmp/yay-install
    (cd /tmp/yay-install && makepkg -si --noconfirm)
    rm -rf /tmp/yay-install
    yay -S --needed --noconfirm wlogout adw-gtk3
fi

# ─── [2/10] Symlink configs ──────────────────────────

step "2/10" "Linking configuration files..."

mkdir -p "$HOME/.config"

for dir in hypr waybar ghostty wofi dunst wlogout nvim gtk-3.0 gtk-4.0; do
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

# Load existing keys if any
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

# ─── [6/10] GTK theme ────────────────────────────────

step "6/10" "Applying GTK theme..."

gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' 2>/dev/null || \
    warn "gsettings not available — GTK theme will apply from settings.ini on first Hyprland session"
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
info "GTK theme set to adw-gtk3-dark"

# ─── [7/10] Waybar scripts ───────────────────────────

step "7/10" "Setting script permissions..."

chmod +x "$DOTDIR/waybar/scripts/"*.sh 2>/dev/null || true
info "Waybar scripts marked executable"

# ─── [8/10] SDDM display manager ─────────────────────

step "8/10" "Setting up SDDM..."

sudo cp -r "$DOTDIR/sddm-theme" /usr/share/sddm/themes/whitebyte
sudo cp "$DOTDIR/sddm/sddm.conf" /etc/sddm.conf
sudo systemctl enable sddm
info "SDDM enabled with whitebyte theme"

# ─── [9/10] Neovim plugins ───────────────────────────

step "9/10" "Installing Neovim plugins..."

nvim --headless "+Lazy! sync" +qa 2>/dev/null || \
    warn "Neovim plugin sync skipped — run 'nvim' to install plugins on first launch"

# ─── [10/10] Summary ─────────────────────────────────

step "10/10" "Setup complete!"

echo ""
echo "  ┌──────────────────────────────────────┐"
echo "  │  Reboot to start Hyprland session    │"
echo "  └──────────────────────────────────────┘"
echo ""
echo "  After reboot, set up password manager:"
echo ""
echo "    gpg --full-generate-key"
echo "    pass init <your-gpg-id>"
echo "    pass git init"
echo ""
echo "  Keybindings:"
echo "    Super+Return    Ghostty terminal"
echo "    Super+D         Wofi launcher"
echo "    Super+M         Maximize toggle"
echo "    Super+F         Fullscreen toggle"
echo "    Super+Q         Close window"
echo "    Ctrl+R          Fuzzy history search"
echo "    s               SSH host picker"
echo "    z <dir>         Smart cd (zoxide)"
echo ""