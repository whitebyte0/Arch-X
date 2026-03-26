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
    sddm qt6-svg qt6-virtualkeyboard \
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
    sudo pacman -S --needed --noconfirm nvidia nvidia-utils lib32-nvidia-utils
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
    yay -S --needed --noconfirm wlogout adw-gtk3 snixembed
else
    warn "yay not found — skipping AUR packages"
fi

# ─── [2/7] SDDM display manager ─────────────────────

step "2/7" "Verifying SDDM..."

# Re-deploy SDDM theme (may be overwritten by package updates)
sudo mkdir -p /usr/share/sddm/themes/whitebyte
sudo cp -r "$DOTDIR/sddm-theme/"* /usr/share/sddm/themes/whitebyte/
info "SDDM theme synced"

# Re-deploy SDDM config
sudo mkdir -p /etc/sddm.conf.d
sudo cp "$DOTDIR/sddm/sddm.conf" /etc/sddm.conf.d/arch-x.conf
info "SDDM config synced"

# Verify SDDM is enabled
if ! systemctl is-enabled sddm &>/dev/null; then
    sudo systemctl enable sddm
    warn "SDDM was disabled — re-enabled"
else
    info "SDDM enabled ✓"
fi

# Verify Hyprland session file exists
if [ -f /usr/share/wayland-sessions/hyprland.desktop ]; then
    info "Hyprland session file ✓"
else
    warn "Hyprland session file missing at /usr/share/wayland-sessions/hyprland.desktop"
fi

# ─── [3/7] Symlinks ──────────────────────────────────

step "3/7" "Verifying symlinks..."

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

# ─── [4/7] Permissions ───────────────────────────────

step "4/7" "Setting permissions..."

chmod +x "$DOTDIR/waybar/scripts/"*.sh 2>/dev/null || true
chmod +x "$DOTDIR/bin/"* 2>/dev/null || true
info "Waybar scripts ✓"
info "Bin scripts ✓"

# ─── [5/7] Reload Hyprland ───────────────────────────

step "5/7" "Reloading Hyprland..."

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

# ─── [6/7] Verify services ──────────────────────────

step "6/7" "Verifying systemd services..."

# SSH agent
if systemctl --user is-enabled ssh-agent.socket &>/dev/null; then
    info "ssh-agent.socket ✓"
else
    systemctl --user enable --now ssh-agent.socket 2>/dev/null && \
        warn "ssh-agent.socket was disabled — re-enabled" || \
        warn "Could not enable ssh-agent.socket"
fi

# Docker
if systemctl is-enabled docker &>/dev/null; then
    info "docker.service ✓"
else
    sudo systemctl enable --now docker && \
        warn "docker was disabled — re-enabled" || \
        warn "Could not enable docker"
fi

# ─── [7/7] Done ──────────────────────────────────────

step "7/7" "Update complete!"
echo ""