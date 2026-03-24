#!/bin/bash
#
# Arch-X — Update an existing installation
#
# Usage:
#   cd ~/Arch-X && git pull && ./update.sh
#
# Safe to run repeatedly — only applies changes, skips what's already done.

set -e
source "$(dirname "$0")/lib/common.sh"
sudo_keepalive

echo ""
echo "  ╔══════════════════════════════════════╗"
echo "  ║         Arch-X Update                ║"
echo "  ╚══════════════════════════════════════╝"
echo ""

# ─── [1/6] Packages ──────────────────────────────────

step "1/6" "Syncing packages..."

install_packages
setup_gpu
install_aur_packages || warn "yay not found — skipping AUR packages"

# ─── [2/6] Symlinks ──────────────────────────────────

step "2/6" "Verifying symlinks..."

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

# ─── [3/6] SDDM theme ────────────────────────────────

step "3/6" "Updating SDDM theme..."

install_sddm_theme

# ─── [4/6] Permissions ───────────────────────────────

step "4/6" "Setting permissions..."

chmod +x "$DOTDIR/waybar/scripts/"*.sh 2>/dev/null || true
chmod +x "$DOTDIR/bin/"* 2>/dev/null || true
info "Scripts ✓"

# ─── [5/6] Reload services ───────────────────────────

step "5/6" "Reloading services..."

# Reload Hyprland config
hyprctl reload 2>/dev/null && info "Hyprland reloaded" || warn "Hyprland not running"

# Restart waybar and dunst
killall waybar 2>/dev/null || true
killall dunst 2>/dev/null || true
sleep 0.5
hyprctl dispatch exec waybar 2>/dev/null
hyprctl dispatch exec dunst 2>/dev/null
info "Waybar and Dunst restarted"

info "Run 'source ~/.zshrc' to apply shell changes"

# ─── [6/6] Done ──────────────────────────────────────

step "6/6" "Update complete!"
echo ""
