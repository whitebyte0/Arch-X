#!/bin/bash
#
# Arch-X — Update an existing installation
#
# Usage:
#   cd ~/Arch-X && git pull && ./update.sh
#
# Safe to run repeatedly — only applies changes, skips what's already done.

set -e

# Keep sudo alive for the entire script
sudo -v
SUDO_PID=
while true; do sudo -n true; sleep 50; done &
SUDO_PID=$!
trap 'kill $SUDO_PID 2>/dev/null' EXIT

DOTDIR="$(cd "$(dirname "$0")" && pwd)"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

step() { echo -e "\n${GREEN}[$1]${NC} $2"; }
warn() { echo -e "${YELLOW}  ⚠ $1${NC}"; }
info() { echo -e "  $1"; }

echo ""
echo "  ╔══════════════════════════════════════╗"
echo "  ║         Arch-X Update                ║"
echo "  ╚══════════════════════════════════════╝"
echo ""

# ─── [1/5] Packages ──────────────────────────────────

step "1/5" "Syncing packages..."

sudo pacman -S --needed --noconfirm \
    hyprland waybar dunst wofi hyprlock grim slurp wf-recorder nwg-look \
    xdg-desktop-portal-hyprland \
    ghostty zsh zsh-autosuggestions zsh-syntax-highlighting \
    fzf fd ripgrep eza bat zoxide yazi sshfs lazygit sshs \
    neovim git docker docker-compose glab \
    ttf-jetbrains-mono-nerd \
    pass pass-otp wl-clipboard gnupg pinentry \
    openssh sshpass libnotify \
    firefox \
    mesa

# GPU drivers — auto-detect
GPU_VENDOR=$(lspci -nn | grep -i vga)
if echo "$GPU_VENDOR" | grep -qi nvidia; then
    info "Detected NVIDIA GPU"
    # Enable multilib repo for 32-bit NVIDIA libs
    if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
        sudo sed -i '/^#\[multilib\]/,/^#Include/ s/^#//' /etc/pacman.conf
        sudo pacman -Sy
    fi
    sudo pacman -S --needed --noconfirm nvidia-dkms nvidia-utils lib32-nvidia-utils
elif echo "$GPU_VENDOR" | grep -qi amd; then
    info "Detected AMD GPU"
    sudo pacman -S --needed --noconfirm vulkan-radeon libva-mesa-driver
elif echo "$GPU_VENDOR" | grep -qi intel; then
    info "Detected Intel GPU"
    sudo pacman -S --needed --noconfirm vulkan-intel intel-media-driver
else
    warn "Could not detect GPU — install drivers manually"
fi

# AUR packages
if command -v yay &>/dev/null; then
    yay -S --needed --noconfirm wlogout adw-gtk3
else
    warn "yay not found — skipping AUR packages"
fi

# ─── [2/5] Symlinks ──────────────────────────────────

step "2/5" "Verifying symlinks..."

mkdir -p "$HOME/.config"

for dir in hypr waybar ghostty wofi dunst wlogout nvim gtk-3.0 gtk-4.0; do
    if [ -L "$HOME/.config/$dir" ] && [ "$(readlink -f "$HOME/.config/$dir")" = "$DOTDIR/$dir" ]; then
        info "~/.config/$dir ✓"
    else
        [ -e "$HOME/.config/$dir" ] && [ ! -L "$HOME/.config/$dir" ] && \
            mv "$HOME/.config/$dir" "$HOME/.config/${dir}.bak" && \
            warn "Backed up ~/.config/$dir → ${dir}.bak"
        ln -sfn "$DOTDIR/$dir" "$HOME/.config/$dir"
        info "~/.config/$dir → linked"
    fi
done

# Home dotfiles
for file in .zshrc .zprofile; do
    if [ -L "$HOME/$file" ] && [ "$(readlink -f "$HOME/$file")" = "$DOTDIR/$file" ]; then
        info "~/$file ✓"
    else
        [ -f "$HOME/$file" ] && [ ! -L "$HOME/$file" ] && \
            mv "$HOME/$file" "$HOME/${file}.bak" && \
            warn "Backed up ~/$file → ${file}.bak"
        ln -sf "$DOTDIR/$file" "$HOME/$file"
        info "~/$file → linked"
    fi
done

# GPG agent
mkdir -p "$HOME/.gnupg" && chmod 700 "$HOME/.gnupg"
ln -sf "$DOTDIR/gnupg/gpg-agent.conf" "$HOME/.gnupg/gpg-agent.conf"
info "~/.gnupg/gpg-agent.conf ✓"

# ─── [3/5] Permissions ───────────────────────────────

step "3/5" "Setting permissions..."

chmod +x "$DOTDIR/waybar/scripts/"*.sh 2>/dev/null || true
chmod +x "$DOTDIR/bin/"* 2>/dev/null || true
info "Waybar scripts ✓"
info "Bin scripts ✓"

# ─── [4/5] Reload services ───────────────────────────

step "4/5" "Reloading services..."

# Reload Hyprland config
hyprctl reload 2>/dev/null && info "Hyprland reloaded" || warn "Hyprland not running"

# Restart waybar and dunst
killall waybar 2>/dev/null || true
killall dunst 2>/dev/null || true
sleep 0.5
hyprctl dispatch exec waybar 2>/dev/null
hyprctl dispatch exec dunst 2>/dev/null
info "Waybar and Dunst restarted"

# Reload zsh config for current shell
info "Run 'source ~/.zshrc' to apply shell changes"

# ─── [5/5] Done ──────────────────────────────────────

step "5/5" "Update complete!"
echo ""