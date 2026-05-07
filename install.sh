#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_TS="$(date +%Y%m%d%H%M%S)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

INSTALLED_PACKAGES=()
INSTALLED_EXTRAS=()
DEPLOYED_CONFIGS=()

backup_if_exists() {
    local target="$1"
    if [[ -e "$target" || -L "$target" ]]; then
        local bak="${target}.bak"
        if [[ -e "$bak" || -L "$bak" ]]; then
            bak="${target}.bak.${BACKUP_TS}"
        fi
        info "Backing up $target -> $bak"
        mv "$target" "$bak"
    fi
}

deploy_file() {
    local src="$1"
    local dest="$2"
    mkdir -p "$(dirname "$dest")"
    backup_if_exists "$dest"
    cp "$src" "$dest"
    DEPLOYED_CONFIGS+=("$dest")
    ok "Deployed $dest"
}

deploy_file_rewriting_home() {
    local src="$1"
    local dest="$2"
    mkdir -p "$(dirname "$dest")"
    backup_if_exists "$dest"
    sed "s|/home/mchavis|$HOME|g" "$src" > "$dest"
    DEPLOYED_CONFIGS+=("$dest")
    ok "Deployed $dest"
}

deploy_dir() {
    local src="$1"
    local dest="$2"
    mkdir -p "$(dirname "$dest")"
    backup_if_exists "$dest"
    cp -r "$src" "$dest"
    DEPLOYED_CONFIGS+=("$dest")
    ok "Deployed $dest/"
}

pkg_install() {
    local pkg="$1"
    if dpkg -s "$pkg" >/dev/null 2>&1; then
        ok "$pkg already installed"
        return 0
    fi

    info "Installing $pkg"
    if sudo apt-get install -y "$pkg"; then
        INSTALLED_PACKAGES+=("$pkg")
        return 0
    fi

    warn "Could not install $pkg"
    return 1
}

main() {
    echo ""
    info "========== Ubuntu quick install =========="

    if [[ "$EUID" -eq 0 ]]; then
        error "Run this script as your normal user."
        exit 1
    fi

    if [[ ! -f /etc/os-release ]]; then
        error "Cannot detect distro: /etc/os-release is missing."
        exit 1
    fi

    # shellcheck disable=SC1091
    source /etc/os-release
    if [[ "${ID:-}" != "ubuntu" ]]; then
        error "This quick installer is for Ubuntu only."
        exit 1
    fi

    info "Checking internet connectivity..."
    if ! curl -fsS --max-time 5 https://archive.ubuntu.com >/dev/null 2>&1; then
        error "No internet connectivity detected."
        exit 1
    fi
    ok "Internet is reachable"

    info "Caching sudo credentials..."
    sudo -v
    while true; do sudo -n true; sleep 50; kill -0 "$$" || exit; done 2>/dev/null &
    SUDO_KEEPALIVE_PID=$!
    trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT

    info "Enabling Ubuntu repositories..."
    sudo apt-get update
    sudo apt-get install -y software-properties-common
    sudo add-apt-repository -y universe

    info "Adding Alacritty PPA..."
    if ! grep -Rqs "aslatter/ppa" /etc/apt/sources.list /etc/apt/sources.list.d 2>/dev/null; then
        sudo add-apt-repository -y ppa:aslatter/ppa
    fi

    info "Refreshing package lists..."
    sudo apt-get update

    info "Installing packages..."
    for pkg in \
        curl \
        git \
        zsh \
        alacritty \
        i3 \
        i3status \
        i3lock \
        neovim \
        tmux \
        neofetch \
        rofi \
        feh \
        xclip \
        imagemagick \
        blueman \
        x11-xserver-utils
    do
        pkg_install "$pkg" || true
    done

    info "Installing shell extras..."
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        ok "oh-my-zsh already installed"
    else
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        INSTALLED_EXTRAS+=("oh-my-zsh")
        ok "Installed oh-my-zsh"
    fi

    local_p10k_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    if [[ -d "$local_p10k_dir" ]]; then
        ok "powerlevel10k already installed"
    else
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$local_p10k_dir"
        INSTALLED_EXTRAS+=("powerlevel10k")
        ok "Installed powerlevel10k"
    fi

    local_autosuggest_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
    if [[ -d "$local_autosuggest_dir" ]]; then
        ok "zsh-autosuggestions already installed"
    else
        git clone https://github.com/zsh-users/zsh-autosuggestions "$local_autosuggest_dir"
        INSTALLED_EXTRAS+=("zsh-autosuggestions")
        ok "Installed zsh-autosuggestions"
    fi

    info "Installing TPM..."
    if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
        ok "TPM already installed"
    else
        git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
        INSTALLED_EXTRAS+=("tpm")
        ok "Installed TPM"
    fi

    info "Deploying configs..."
    deploy_file_rewriting_home "$SCRIPT_DIR/Alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
    deploy_file "$SCRIPT_DIR/Alacritty/one-dark.toml" "$HOME/.config/alacritty/one-dark.toml"
    deploy_file_rewriting_home "$SCRIPT_DIR/i3/i3/config" "$HOME/.config/i3/config"
    deploy_file "$SCRIPT_DIR/i3-status/i3status/config" "$HOME/.config/i3status/config"
    deploy_dir "$SCRIPT_DIR/nvim" "$HOME/.config/nvim"
    deploy_file "$SCRIPT_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"
    deploy_file "$SCRIPT_DIR/neofetch/config.conf" "$HOME/.config/neofetch/config.conf"
    deploy_file "$SCRIPT_DIR/neofetch/mylogo.txt" "$HOME/.config/neofetch/mylogo.txt"
    deploy_file "$SCRIPT_DIR/.zshrc" "$HOME/.zshrc"
    deploy_file "$SCRIPT_DIR/.p10k.zsh" "$HOME/.p10k.zsh"
    deploy_file "$SCRIPT_DIR/.local/bin/picker.sh" "$HOME/.local/bin/picker.sh"
    chmod +x "$HOME/.local/bin/picker.sh"

    if [[ -f "$SCRIPT_DIR/shell.sh" ]]; then
        deploy_file "$SCRIPT_DIR/shell.sh" "$HOME/.shell.sh"
    fi

    if command -v zsh >/dev/null 2>&1; then
        current_shell="$(getent passwd "$USER" | cut -d: -f7)"
        zsh_path="$(command -v zsh)"
        if [[ "$current_shell" != "$zsh_path" ]]; then
            info "Changing default shell to zsh"
            sudo chsh -s "$zsh_path" "$USER"
            ok "Default shell changed to zsh"
        else
            ok "Default shell is already zsh"
        fi
    fi

    echo ""
    info "========== Summary =========="
    if [[ ${#INSTALLED_PACKAGES[@]} -gt 0 ]]; then
        ok "Installed packages: ${INSTALLED_PACKAGES[*]}"
    else
        ok "All requested packages were already installed"
    fi

    if [[ ${#INSTALLED_EXTRAS[@]} -gt 0 ]]; then
        ok "Installed extras: ${INSTALLED_EXTRAS[*]}"
    fi

    if [[ ${#DEPLOYED_CONFIGS[@]} -gt 0 ]]; then
        ok "Deployed configs:"
        for cfg in "${DEPLOYED_CONFIGS[@]}"; do
            echo "  $cfg"
        done
    fi

    echo ""
    ok "Ubuntu quick install complete"
}

main "$@"
