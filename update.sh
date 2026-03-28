#!/bin/bash
#
# Arch-X — Update an existing installation
#
# Usage:
#   cd ~/Arch-X && git pull && ./update.sh
#
# Safe to run repeatedly — only applies changes, skips what's already done.

set -eo pipefail
source "$(dirname "$0")/lib/common.sh"
sudo_keepalive

echo ""
echo "  ╔══════════════════════════════════════╗"
echo "  ║         Arch-X Update                ║"
echo "  ╚══════════════════════════════════════╝"
echo ""

# ─── [1/7] Packages ──────────────────────────────────

step "1/7" "Syncing packages..."

install_packages
setup_gpu
install_aur_packages || warn "yay not found — skipping AUR packages"

# ─── [2/7] Symlinks ──────────────────────────────────

step "2/7" "Verifying symlinks..."

mkdir -p "$HOME/.config"

for dir in hypr waybar ghostty wofi ags wlogout nvim gtk-3.0 gtk-4.0; do
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
for file in .zshrc; do
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

# Ensure hypr-local overrides exist (prevents Hyprland source= errors)
mkdir -p "$HOME/.config/hypr-local"
[ -f "$HOME/.config/hypr-local/monitors.conf" ] || : > "$HOME/.config/hypr-local/monitors.conf"
[ -f "$HOME/.config/hypr-local/gpu.conf" ]      || : > "$HOME/.config/hypr-local/gpu.conf"
info "~/.config/hypr-local ✓"

# ─── [3/7] SDDM theme ────────────────────────────────

step "3/7" "Updating SDDM theme..."

install_sddm_theme

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

# ─── [4/7] Permissions ───────────────────────────────

step "4/7" "Setting permissions..."

chmod +x "$DOTDIR/waybar/scripts/"*.sh 2>/dev/null || true
chmod +x "$DOTDIR/bin/"* 2>/dev/null || true
info "Scripts ✓"

# ─── [5/7] Reload Hyprland ───────────────────────────

step "5/7" "Reloading services..."

# Reload Hyprland config
hyprctl reload 2>/dev/null && info "Hyprland reloaded" || warn "Hyprland not running"

# Restart waybar, AGS, and snixembed (tray bridge)
killall waybar 2>/dev/null || true
killall snixembed 2>/dev/null || true
ags quit 2>/dev/null || true
sleep 0.5
hyprctl dispatch exec "snixembed --fork" 2>/dev/null
hyprctl dispatch exec waybar 2>/dev/null
hyprctl dispatch exec "ags run --gtk 4 -d ~/.config/ags/" 2>/dev/null
info "Waybar, AGS, and snixembed restarted"

# Ensure swww is running (replaces hyprpaper)
if ! pgrep -x swww-daemon >/dev/null; then
    hyprctl dispatch exec "swww-daemon" 2>/dev/null
    sleep 0.5
    swww img ~/Pictures/wallpaper.jpg 2>/dev/null
    info "swww-daemon started"
else
    info "swww-daemon running ✓"
fi

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
