#!/bin/bash
#
# Arch-X — Automated Arch Linux + Hyprland environment setup
#
# Usage:
#   git clone <repo> ~/Arch-X && cd ~/Arch-X && ./install.sh
#
# Assumes: fresh Arch Linux install with a non-root user and sudo access.

set -e

# Keep sudo alive for the entire script
sudo -v
trap 'kill $(jobs -p) 2>/dev/null' EXIT
while true; do sudo -n true; sleep 50; done &

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

# ─── [1/9] Packages ──────────────────────────────────

step "1/9" "Installing packages..."

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
    sudo pacman -S --needed --noconfirm nvidia-open nvidia-utils lib32-nvidia-utils
    # Enable DRM kernel mode setting for Hyprland
    if grep -q "nvidia_drm.modeset=1" /proc/cmdline 2>/dev/null; then
        info "nvidia_drm.modeset=1 already active"
    elif [ -f /etc/default/grub ]; then
        if ! grep -q "nvidia_drm.modeset=1" /etc/default/grub; then
            sudo sed -i 's/\(GRUB_CMDLINE_LINUX_DEFAULT="[^"]*\)/\1 nvidia_drm.modeset=1/' /etc/default/grub
            sudo grub-mkconfig -o /boot/grub/grub.cfg
            info "Added nvidia_drm.modeset=1 to GRUB and regenerated config"
        fi
    else
        # systemd-boot: check common entry paths
        BOOT_ENTRIES=""
        for dir in /boot/loader/entries /efi/loader/entries; do
            if sudo test -d "$dir"; then
                BOOT_ENTRIES="$dir"
                break
            fi
        done
        if [ -n "$BOOT_ENTRIES" ]; then
            for entry in "$BOOT_ENTRIES"/*.conf; do
                if sudo test -f "$entry" && ! sudo grep -q "nvidia_drm.modeset=1" "$entry"; then
                    sudo sed -i '/^options/s/$/ nvidia_drm.modeset=1/' "$entry"
                    info "Added nvidia_drm.modeset=1 to $(basename "$entry")"
                fi
            done
        else
            warn "Add 'nvidia_drm.modeset=1' to your bootloader kernel params manually"
        fi
    fi
elif echo "$GPU_VENDOR" | grep -qi amd; then
    info "Detected AMD GPU"
    sudo pacman -S --needed --noconfirm vulkan-radeon libva-mesa-driver
elif echo "$GPU_VENDOR" | grep -qi intel; then
    info "Detected Intel GPU"
    sudo pacman -S --needed --noconfirm vulkan-intel intel-media-driver
else
    warn "Could not detect GPU vendor — install drivers manually"
    info "GPU info: $GPU_VENDOR"
fi

# AUR packages (requires yay)
if command -v yay &>/dev/null; then
    yay -S --needed --noconfirm wlogout adw-gtk3 snixembed
else
    warn "yay not found — installing yay first..."
    sudo pacman -S --needed --noconfirm base-devel
    git clone https://aur.archlinux.org/yay.git /tmp/yay-install
    (cd /tmp/yay-install && makepkg -si --noconfirm)
    rm -rf /tmp/yay-install
    yay -S --needed --noconfirm wlogout adw-gtk3 snixembed
fi

# ─── [2/9] Symlink configs ───────────────────────────

step "2/9" "Linking configuration files..."

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

# .zprofile (auto-start Hyprland on TTY1)
ln -sf "$DOTDIR/.zprofile" "$HOME/.zprofile"
info "~/.zprofile → $DOTDIR/.zprofile"

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

# ─── [3/9] Default shell ─────────────────────────────

step "3/9" "Setting zsh as default shell..."

if [ "$SHELL" != "/usr/bin/zsh" ]; then
    chsh -s /usr/bin/zsh
    info "Default shell changed to zsh"
else
    info "Already using zsh"
fi

# ─── [4/9] SSH agent ─────────────────────────────────

step "4/9" "Enabling SSH agent..."

systemctl --user enable --now ssh-agent.socket 2>/dev/null || \
    systemctl --user enable --now ssh-agent 2>/dev/null || \
    warn "Could not enable ssh-agent service — enable manually after reboot"

# Load existing keys if any
grep -rl "PRIVATE KEY" ~/.ssh/ 2>/dev/null | xargs -r ssh-add 2>/dev/null || true
info "SSH agent configured"

# ─── [5/9] Docker ────────────────────────────────────

step "5/9" "Enabling Docker..."

sudo systemctl enable --now docker
if ! groups "$USER" | grep -q docker; then
    sudo usermod -aG docker "$USER"
    info "Added $USER to docker group (takes effect after re-login)"
else
    info "Already in docker group"
fi

# ─── [6/10] SDDM display manager ────────────────────

step "6/10" "Configuring SDDM..."

# Deploy SDDM theme
sudo mkdir -p /usr/share/sddm/themes/whitebyte
sudo cp -r "$DOTDIR/sddm-theme/"* /usr/share/sddm/themes/whitebyte/
info "SDDM theme deployed to /usr/share/sddm/themes/whitebyte"

# Deploy SDDM config
sudo mkdir -p /etc/sddm.conf.d
sudo cp "$DOTDIR/sddm/sddm.conf" /etc/sddm.conf.d/arch-x.conf
info "SDDM config deployed to /etc/sddm.conf.d/arch-x.conf"

# Enable SDDM
sudo systemctl enable sddm
info "SDDM enabled (will start on next boot)"

# ─── [7/10] GTK theme ─────────────────────────────────

step "7/10" "Applying GTK theme..."

gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' 2>/dev/null || \
    warn "gsettings not available — GTK theme will apply from settings.ini on first Hyprland session"
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
info "GTK theme set to adw-gtk3-dark"

# ─── [8/10] Waybar scripts ────────────────────────────

step "8/10" "Setting script permissions..."

chmod +x "$DOTDIR/waybar/scripts/"*.sh 2>/dev/null || true
info "Waybar scripts marked executable"

# ─── [9/10] Neovim plugins ────────────────────────────

step "9/10" "Installing Neovim plugins..."

nvim --headless "+Lazy! sync" +qa 2>/dev/null || \
    warn "Neovim plugin sync skipped — run 'nvim' to install plugins on first launch"

# ─── [10/10] Summary ──────────────────────────────────

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
echo "    sshs            SSH host picker"
echo "    z <dir>         Smart cd (zoxide)"
echo ""