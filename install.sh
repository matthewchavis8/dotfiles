#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Dotfiles Install Script
# Bootstraps a fresh Linux machine with packages and config files.
# Supports: Arch (pacman/yay), Ubuntu/Debian (apt), Fedora (dnf)
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_TS="$(date +%Y%m%d%H%M%S)"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

# Track what was installed for the summary
INSTALLED_PACKAGES=()
INSTALLED_EXTRAS=()
DEPLOYED_CONFIGS=()

# ==============================================================================
# [1/9] Preflight checks
# ==============================================================================
echo ""
info "========== [1/9] Preflight checks =========="

if [[ "$EUID" -eq 0 ]]; then
    error "Do not run this script as root. Run as your normal user — sudo will be used where needed."
    exit 1
fi

info "Checking internet connectivity..."
if ! curl -sf --max-time 5 https://archlinux.org > /dev/null 2>&1 &&
   ! curl -sf --max-time 5 https://google.com > /dev/null 2>&1; then
    error "No internet connectivity detected."
    exit 1
fi
ok "Internet is reachable."

info "Caching sudo credentials..."
sudo -v
# Keep sudo alive in the background
while true; do sudo -n true; sleep 50; kill -0 "$$" || exit; done 2>/dev/null &
SUDO_KEEPALIVE_PID=$!
trap 'kill $SUDO_KEEPALIVE_PID 2>/dev/null' EXIT

ok "Preflight checks passed."

# ==============================================================================
# [2/9] Detect distro
# ==============================================================================
echo ""
info "========== [2/9] Detecting distribution =========="

PKG_MGR=""
HAS_YAY=false

if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    case "${ID:-}" in
        arch|endeavouros|manjaro)
            PKG_MGR="pacman"
            if command -v yay &>/dev/null; then
                HAS_YAY=true
                ok "Detected Arch-based distro with yay (AUR helper)."
            else
                ok "Detected Arch-based distro (no yay found — AUR packages will be skipped)."
            fi
            ;;
        ubuntu|debian|linuxmint|pop)
            PKG_MGR="apt"
            ok "Detected Debian/Ubuntu-based distro."
            ;;
        fedora)
            PKG_MGR="dnf"
            ok "Detected Fedora."
            ;;
        *)
            error "Unsupported distro: ${ID:-unknown}"
            exit 1
            ;;
    esac
else
    error "Cannot detect distro — /etc/os-release not found."
    exit 1
fi

# ==============================================================================
# [3/9] Install packages
# ==============================================================================
echo ""
info "========== [3/9] Installing packages =========="

pkg_install() {
    local pkg="$1"
    case "$PKG_MGR" in
        pacman)
            if ! pacman -Qi "$pkg" &>/dev/null; then
                info "Installing $pkg..."
                sudo pacman -S --noconfirm --needed "$pkg"
                INSTALLED_PACKAGES+=("$pkg")
            else
                ok "$pkg already installed."
            fi
            ;;
        apt)
            if ! dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"; then
                info "Installing $pkg..."
                sudo apt-get install -y "$pkg"
                INSTALLED_PACKAGES+=("$pkg")
            else
                ok "$pkg already installed."
            fi
            ;;
        dnf)
            if ! rpm -q "$pkg" &>/dev/null; then
                info "Installing $pkg..."
                sudo dnf install -y "$pkg"
                INSTALLED_PACKAGES+=("$pkg")
            else
                ok "$pkg already installed."
            fi
            ;;
    esac
}

# Update package database
info "Updating package database..."
case "$PKG_MGR" in
    pacman) sudo pacman -Sy ;;
    apt)    sudo apt-get update ;;
    dnf)    sudo dnf check-update || true ;;
esac

# On Ubuntu, add Alacritty PPA if needed
if [[ "$PKG_MGR" == "apt" ]]; then
    if ! dpkg -l alacritty 2>/dev/null | grep -q "^ii"; then
        if ! grep -rq "aslatter/ppa" /etc/apt/sources.list.d/ 2>/dev/null; then
            info "Adding Alacritty PPA..."
            sudo add-apt-repository -y ppa:aslatter/ppa
            sudo apt-get update
        fi
    fi
fi

# Core packages — map names per distro where they differ
CORE_PACKAGES=(i3-wm i3status i3lock alacritty tmux neovim zsh feh rofi curl git xclip)

# Handle package name differences
case "$PKG_MGR" in
    pacman)
        CORE_PACKAGES+=(i3-wm)
        # pacman uses 'i3-wm' — already in list, but i3status/i3lock are correct
        ;;
    apt)
        # Debian/Ubuntu package names
        CORE_PACKAGES=(i3 i3status i3lock alacritty tmux neovim zsh feh rofi curl git xclip)
        ;;
    dnf)
        CORE_PACKAGES=(i3 i3status i3lock alacritty tmux neovim zsh feh rofi curl git xclip)
        ;;
esac

for pkg in "${CORE_PACKAGES[@]}"; do
    pkg_install "$pkg"
done

# neofetch — archived, may not be available
info "Attempting to install neofetch (may be unavailable — it's archived)..."
if ! pkg_install neofetch 2>/dev/null; then
    warn "neofetch is not available in your package repos. Skipping."
fi

# dconf
case "$PKG_MGR" in
    pacman|dnf) pkg_install dconf ;;
    apt)        pkg_install dconf-cli ;;
esac

# Nerd Fonts
echo ""
info "Installing Nerd Fonts..."
if [[ "$PKG_MGR" == "pacman" && "$HAS_YAY" == true ]]; then
    if ! yay -Qi nerd-fonts &>/dev/null; then
        info "Installing nerd-fonts meta-package from AUR via yay..."
        yay -S --noconfirm nerd-fonts
        INSTALLED_PACKAGES+=("nerd-fonts (AUR)")
    else
        ok "nerd-fonts already installed."
    fi
else
    FONT_DIR="$HOME/.local/share/fonts"
    if fc-list | grep -qi "Nerd" 2>/dev/null; then
        ok "Nerd Fonts already detected."
    else
        info "Downloading Nerd Fonts from GitHub..."
        mkdir -p "$FONT_DIR"
        NERD_FONT_VERSION=$(curl -sf "https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
        if [[ -z "$NERD_FONT_VERSION" ]]; then
            warn "Could not determine latest Nerd Fonts version. Using v3.3.0 as fallback."
            NERD_FONT_VERSION="v3.3.0"
        fi
        info "Downloading NerdFontsSymbolsOnly ($NERD_FONT_VERSION)..."
        TMPDIR_FONTS="$(mktemp -d)"
        # Download a selection of popular Nerd Fonts
        for font_name in FiraCode JetBrainsMono Hack UbuntuMono DejaVuSansMono NerdFontsSymbolsOnly; do
            info "  Downloading $font_name..."
            if curl -sfL "https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONT_VERSION}/${font_name}.tar.xz" -o "$TMPDIR_FONTS/${font_name}.tar.xz"; then
                tar -xf "$TMPDIR_FONTS/${font_name}.tar.xz" -C "$FONT_DIR"
            elif curl -sfL "https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONT_VERSION}/${font_name}.zip" -o "$TMPDIR_FONTS/${font_name}.zip"; then
                unzip -qo "$TMPDIR_FONTS/${font_name}.zip" -d "$FONT_DIR"
            else
                warn "  Failed to download $font_name, skipping."
            fi
        done
        rm -rf "$TMPDIR_FONTS"
        fc-cache -f "$FONT_DIR"
        INSTALLED_PACKAGES+=("Nerd Fonts")
        ok "Nerd Fonts installed to $FONT_DIR"
    fi
fi

ok "Package installation complete."

# ==============================================================================
# [4/9] Install shell extras
# ==============================================================================
echo ""
info "========== [4/9] Installing shell extras =========="

# oh-my-zsh
if [[ -d "$HOME/.oh-my-zsh" ]]; then
    ok "oh-my-zsh already installed."
else
    info "Installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    INSTALLED_EXTRAS+=("oh-my-zsh")
    ok "oh-my-zsh installed."
fi

# powerlevel10k
P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
if [[ -d "$P10K_DIR" ]]; then
    ok "powerlevel10k already installed."
else
    info "Installing powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
    INSTALLED_EXTRAS+=("powerlevel10k")
    ok "powerlevel10k installed."
fi

# zsh-autosuggestions
ZSH_AS_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
if [[ -d "$ZSH_AS_DIR" ]]; then
    ok "zsh-autosuggestions already installed."
else
    info "Installing zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_AS_DIR"
    INSTALLED_EXTRAS+=("zsh-autosuggestions")
    ok "zsh-autosuggestions installed."
fi

# ==============================================================================
# [5/9] Install TPM (Tmux Plugin Manager)
# ==============================================================================
echo ""
info "========== [5/9] Installing TPM (Tmux Plugin Manager) =========="

TPM_DIR="$HOME/.tmux/plugins/tpm"
if [[ -d "$TPM_DIR" ]]; then
    ok "TPM already installed."
else
    info "Cloning TPM..."
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
    INSTALLED_EXTRAS+=("tpm")
    ok "TPM installed."
fi

# ==============================================================================
# [6/9] Deploy configs
# ==============================================================================
echo ""
info "========== [6/9] Deploying config files =========="

# Backup helper: moves existing file/dir to .bak (with timestamp if .bak exists)
backup_if_exists() {
    local target="$1"
    if [[ -e "$target" || -L "$target" ]]; then
        local bak="${target}.bak"
        if [[ -e "$bak" ]]; then
            bak="${target}.bak.${BACKUP_TS}"
        fi
        info "Backing up $(basename "$target") → $(basename "$bak")"
        mv "$target" "$bak"
    fi
}

# Deploy a single file
deploy_file() {
    local src="$1"
    local dest="$2"
    mkdir -p "$(dirname "$dest")"
    backup_if_exists "$dest"
    cp "$src" "$dest"
    DEPLOYED_CONFIGS+=("$dest")
    ok "Deployed $(basename "$dest")"
}

# Deploy a directory (recursive copy)
deploy_dir() {
    local src="$1"
    local dest="$2"
    mkdir -p "$(dirname "$dest")"
    backup_if_exists "$dest"
    cp -r "$src" "$dest"
    DEPLOYED_CONFIGS+=("$dest")
    ok "Deployed $(basename "$dest")/"
}

# nvim/
deploy_dir "$SCRIPT_DIR/nvim" "$HOME/.config/nvim"

# Alacritty
deploy_file "$SCRIPT_DIR/Alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
deploy_file "$SCRIPT_DIR/Alacritty/one-dark.toml" "$HOME/.config/alacritty/one-dark.toml"

# i3
deploy_file "$SCRIPT_DIR/i3/i3/config" "$HOME/.config/i3/config"

# i3status
deploy_file "$SCRIPT_DIR/i3-status/i3status/config" "$HOME/.config/i3status/config"

# tmux
deploy_file "$SCRIPT_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"
deploy_dir "$SCRIPT_DIR/tmux/.tmux/plugins/tmux-onedark-theme" "$HOME/.tmux/plugins/tmux-onedark-theme"

# neofetch
deploy_file "$SCRIPT_DIR/neofetch/config.conf" "$HOME/.config/neofetch/config.conf"
deploy_file "$SCRIPT_DIR/neofetch/mylogo.txt" "$HOME/.config/neofetch/mylogo.txt"

# zsh
deploy_file "$SCRIPT_DIR/.zshrc" "$HOME/.zshrc"
deploy_file "$SCRIPT_DIR/.p10k.zsh" "$HOME/.p10k.zsh"

ok "All configs deployed."

# ==============================================================================
# [7/9] Apply GNOME Terminal theme
# ==============================================================================
echo ""
info "========== [7/9] Applying GNOME Terminal theme =========="

if command -v gnome-terminal &>/dev/null && command -v dconf &>/dev/null; then
    info "Running one-dark.sh for GNOME Terminal..."
    bash "$SCRIPT_DIR/one-dark.sh"
    ok "GNOME Terminal One Dark theme applied."
else
    warn "gnome-terminal or dconf not found — skipping GNOME Terminal theme."
fi

# ==============================================================================
# [8/9] Change default shell to zsh
# ==============================================================================
echo ""
info "========== [8/9] Setting default shell to zsh =========="

CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"
ZSH_PATH="$(which zsh)"

if [[ "$CURRENT_SHELL" == "$ZSH_PATH" ]]; then
    ok "Default shell is already zsh."
else
    info "Changing default shell to zsh..."
    chsh -s "$ZSH_PATH"
    ok "Default shell changed to zsh."
fi

# ==============================================================================
# [9/9] Summary
# ==============================================================================
echo ""
info "========== [9/9] Summary =========="
echo ""

if [[ ${#INSTALLED_PACKAGES[@]} -gt 0 ]]; then
    ok "Packages installed: ${INSTALLED_PACKAGES[*]}"
else
    ok "All packages were already installed."
fi

if [[ ${#INSTALLED_EXTRAS[@]} -gt 0 ]]; then
    ok "Extras installed: ${INSTALLED_EXTRAS[*]}"
else
    ok "All extras (oh-my-zsh, powerlevel10k, etc.) were already present."
fi

if [[ ${#DEPLOYED_CONFIGS[@]} -gt 0 ]]; then
    ok "Configs deployed:"
    for cfg in "${DEPLOYED_CONFIGS[@]}"; do
        echo "      $cfg"
    done
fi

echo ""
warn "=== Reminders ==="
warn "1. Log out and back in (or reboot) for zsh to become your default shell."
warn "2. In tmux, press prefix + I (Ctrl-s + I) to install tmux plugins via TPM."
warn "3. Open nvim — lazy.nvim should auto-sync plugins on first launch."
warn "4. The i3 config has a hardcoded wallpaper path: /home/mchavis/Downloads/a_sculpture_of_a_man_with_a_face_on_his_head.png"
warn "   Update this path in ~/.config/i3/config if your wallpaper is elsewhere."
echo ""
ok "Done! Enjoy your new setup."
