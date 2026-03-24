#!/bin/bash
# Arch-X shared functions — sourced by install.sh and update.sh

DOTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ─── Colors + logging ────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

step() { echo -e "\n${GREEN}[$1]${NC} $2"; }
warn() { echo -e "${YELLOW}  ⚠ $1${NC}"; }
info() { echo -e "  $1"; }

# ─── Sudo keepalive ──────────────────────────────────
sudo_keepalive() {
    sudo -v
    while true; do sudo -n true; sleep 50; done &
    SUDO_KEEPALIVE_PID=$!
    trap 'kill $SUDO_KEEPALIVE_PID 2>/dev/null' EXIT
}

# ─── Package installation ────────────────────────────
install_packages() {
    local pkgs
    pkgs=$(grep -v '^\s*#\|^\s*$' "$DOTDIR/packages.txt" | tr '\n' ' ')
    sudo pacman -S --needed --noconfirm $pkgs
}

install_aur_packages() {
    local pkgs
    pkgs=$(grep -v '^\s*#\|^\s*$' "$DOTDIR/packages-aur.txt" | tr '\n' ' ')
    if command -v yay &>/dev/null; then
        yay -S --needed --noconfirm $pkgs
        return 0
    fi
    return 1
}

# ─── GPU auto-detection ──────────────────────────────
setup_gpu() {
    local GPU_VENDOR
    GPU_VENDOR=$(lspci -nn | grep -i vga)

    if echo "$GPU_VENDOR" | grep -qi nvidia; then
        info "Detected NVIDIA GPU"
        if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
            sudo sed -i '/^#\[multilib\]/,/^#Include/ s/^#//' /etc/pacman.conf
            sudo pacman -Sy
        fi
        sudo pacman -S --needed --noconfirm linux-headers nvidia-dkms nvidia-utils lib32-nvidia-utils
        mkdir -p "$HOME/.config/hypr"
        cat > "$HOME/.config/hypr/gpu.conf" << 'GPUEOF'
env = LIBVA_DRIVER_NAME,nvidia
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = GBM_BACKEND,nvidia-drm
env = WLR_NO_HARDWARE_CURSORS,1
env = NVD_BACKEND,direct
GPUEOF
        info "Created ~/.config/hypr/gpu.conf with NVIDIA env vars"
        if ! grep -q "nvidia_drm.modeset=1" /proc/cmdline; then
            if [ -f /etc/kernel/cmdline ]; then
                sudo sed -i 's/$/ nvidia_drm.modeset=1/' /etc/kernel/cmdline
                sudo reinstall-kernels 2>/dev/null || sudo mkinitcpio -P
                info "Added nvidia_drm.modeset=1 to /etc/kernel/cmdline"
            elif [ -f /etc/default/grub ]; then
                sudo sed -i 's/\(GRUB_CMDLINE_LINUX_DEFAULT="[^"]*\)/\1 nvidia_drm.modeset=1/' /etc/default/grub
                sudo grub-mkconfig -o /boot/grub/grub.cfg
                info "Added nvidia_drm.modeset=1 to GRUB config"
            else
                warn "Could not detect bootloader — add 'nvidia_drm.modeset=1' to kernel params manually"
            fi
            warn "Reboot required for nvidia_drm.modeset=1 to take effect"
        fi
    elif echo "$GPU_VENDOR" | grep -qi amd; then
        info "Detected AMD GPU"
        sudo pacman -S --needed --noconfirm vulkan-radeon libva-mesa-driver
        mkdir -p "$HOME/.config/hypr" && : > "$HOME/.config/hypr/gpu.conf"
    elif echo "$GPU_VENDOR" | grep -qi intel; then
        info "Detected Intel GPU"
        sudo pacman -S --needed --noconfirm vulkan-intel intel-media-driver
        mkdir -p "$HOME/.config/hypr" && : > "$HOME/.config/hypr/gpu.conf"
    else
        warn "Could not detect GPU vendor — install drivers manually"
        info "GPU info: $GPU_VENDOR"
        mkdir -p "$HOME/.config/hypr" && : > "$HOME/.config/hypr/gpu.conf"
    fi
}

# ─── SDDM theme ──────────────────────────────────────
install_sddm_theme() {
    sudo cp -r "$DOTDIR/sddm-theme" /usr/share/sddm/themes/whitebyte
    info "Installed SDDM theme to /usr/share/sddm/themes/whitebyte"

    sudo mkdir -p /etc/sddm.conf.d
    sudo cp "$DOTDIR/sddm/sddm.conf" /etc/sddm.conf.d/sddm.conf
    info "Installed SDDM config to /etc/sddm.conf.d/sddm.conf"
}

# ─── Wallpaper fetching (Wallhaven API) ──────────────
fetch_wallpaper() {
    local query="${1:-cyberpunk}"
    local dest="${2:-$HOME/Pictures/wallpaper.jpg}"
    local min_res="${3:-2560x1440}"

    mkdir -p "$(dirname "$dest")"

    local api="https://wallhaven.cc/api/v1/search"
    local params="q=${query}&atleast=${min_res}&sorting=random&purity=100"

    local img_url
    img_url=$(curl -sf "${api}?${params}" | jq -r '.data[0].path // empty')

    if [[ -n "$img_url" ]]; then
        curl -sfL "$img_url" -o "$dest"
        return 0
    fi
    return 1
}
