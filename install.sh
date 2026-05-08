#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

main() {
    if [[ "$EUID" -eq 0 ]]; then
        error "Run this script as your normal user."
        exit 1
    fi

    if [[ ! -f /etc/os-release ]] || ! grep -q 'ID=ubuntu' /etc/os-release; then
        error "This installer is for Ubuntu only."
        exit 1
    fi

    info "Updating package lists..."
    sudo apt-get -o Acquire::Check-Valid-Until=false update

    info "Installing packages..."
    sudo apt-get install -y \
        curl \
        git \
        zsh \
        alacritty \
        i3 \
        i3status \
        i3lock \
        tmux \
        fastfetch \
        rofi \
        feh \
        xclip \
        ripgrep \
        imagemagick \
        blueman \
        x11-xserver-utils \
        clang \
        clangd \
        cargo \
        cmake \
        ninja-build \
        gettext \
        unzip \
        build-essential

    export PATH="$HOME/.cargo/bin:$PATH"
    TREE_SITTER_VERSION="$(tree-sitter --version 2>/dev/null || true)"
    if ! command -v tree-sitter >/dev/null 2>&1 || ! grep -Eq 'tree-sitter 0\.(2[6-9]|[3-9][0-9])' <<< "$TREE_SITTER_VERSION"; then
        info "Installing tree-sitter-cli 0.26.1..."
        cargo install tree-sitter-cli --version 0.26.1 --locked
    else
        ok "tree-sitter-cli already installed, skipping."
    fi

    info "Building Neovim from source (latest)..."
    NVIM_BUILD_DIR="$(mktemp -d)"
    git clone --depth=1 https://github.com/neovim/neovim "$NVIM_BUILD_DIR/neovim"
    make -C "$NVIM_BUILD_DIR/neovim" CMAKE_BUILD_TYPE=RelWithDebInfo -j"$(nproc)"
    sudo make -C "$NVIM_BUILD_DIR/neovim" install
    rm -rf "$NVIM_BUILD_DIR"
    ok "Neovim $(nvim --version | head -1) installed."

    info "Installing 0xProto Nerd Font..."
    mkdir -p "$HOME/.local/share/fonts"
    curl -fLo "$HOME/.local/share/fonts/0xProtoNerdFont.zip" \
        "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/0xProto.zip"
    unzip -o "$HOME/.local/share/fonts/0xProtoNerdFont.zip" -d "$HOME/.local/share/fonts/" '*.ttf'
    rm "$HOME/.local/share/fonts/0xProtoNerdFont.zip"
    fc-cache -f "$HOME/.local/share/fonts"
    ok "0xProto Nerd Font installed."

    info "Installing Oh My Zsh..."
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
        ok "Oh My Zsh already installed, skipping."
    fi

    info "Installing Powerlevel10k theme..."
    P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    if [[ ! -d "$P10K_DIR" ]]; then
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
    else
        ok "Powerlevel10k already installed, skipping."
    fi

    info "Installing zsh plugins..."
    AUTOSUG_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
    if [[ ! -d "$AUTOSUG_DIR" ]]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions "$AUTOSUG_DIR"
    else
        ok "zsh-autosuggestions already installed, skipping."
    fi

    info "Installing Tmux Plugin Manager..."
    TPM_DIR="$HOME/.tmux/plugins/tpm"
    if [[ ! -d "$TPM_DIR" ]]; then
        git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
    else
        ok "TPM already installed, skipping."
    fi

    info "Setting zsh as default shell..."
    sudo usermod --shell "$(which zsh)" "$USER"

    info "Deploying configs..."
    deploy() {
        local src="$1" dest="$2"
        mkdir -p "$(dirname "$dest")"
        cp "$src" "$dest"
        ok "  $dest"
    }

    mkdir -p "$HOME/.config/alacritty"
    sed "s|/home/mchavis|$HOME|g" "$SCRIPT_DIR/Alacritty/alacritty.toml" > "$HOME/.config/alacritty/alacritty.toml" && ok "  $HOME/.config/alacritty/alacritty.toml"
    deploy "$SCRIPT_DIR/Alacritty/one-dark.toml"         "$HOME/.config/alacritty/one-dark.toml"
    mkdir -p "$HOME/.config/i3"
    sed "s|/home/mchavis|$HOME|g" "$SCRIPT_DIR/i3/i3/config" > "$HOME/.config/i3/config" && ok "  $HOME/.config/i3/config"
    deploy "$SCRIPT_DIR/i3-status/i3status/config"       "$HOME/.config/i3status/config"
    info "Bootstrapping clean NvChad starter..."
    rm -rf "$HOME/.config/nvim"
    git clone https://github.com/NvChad/starter "$HOME/.config/nvim"
    rm -rf "$HOME/.config/nvim/.git"
    ok "  $HOME/.config/nvim/ NvChad starter"

    info "Installing NvChad base plugins (this may take a minute)..."
    nvim --headless "+Lazy! sync" +qa 2>&1 || true

    info "Overlaying custom Neovim config..."
    cp -a "$SCRIPT_DIR/nvim/." "$HOME/.config/nvim/" && ok "  $HOME/.config/nvim/"

    info "Syncing Neovim plugins and tooling..."
    nvim --headless "+Lazy! sync" +qa 2>&1 || true
    nvim --headless "+MasonInstallAll" +qa 2>&1 || true

    info "Installing tree-sitter parsers (synchronous)..."
    nvim --headless -c "lua require('nvim-treesitter').install({ 'c', 'cpp', 'lua', 'vim', 'vimdoc', 'html', 'css' }):wait(300000)" -c "qa!" 2>&1

    info "Compiling NvChad base46 theme cache..."
    nvim --headless -c "lua require('base46').load_all_highlights()" -c "qa!" 2>&1 || true
    deploy "$SCRIPT_DIR/tmux/.tmux.conf"                 "$HOME/.tmux.conf"
    "$HOME/.tmux/plugins/tpm/bin/install_plugins"
    deploy "$SCRIPT_DIR/neofetch/config.conf"            "$HOME/.config/fastfetch/config.conf"
    deploy "$SCRIPT_DIR/neofetch/mylogo.txt"             "$HOME/.config/fastfetch/mylogo.txt"
    deploy "$SCRIPT_DIR/.zshrc"                          "$HOME/.zshrc"
    deploy "$SCRIPT_DIR/.p10k.zsh"                       "$HOME/.p10k.zsh"
    deploy "$SCRIPT_DIR/.local/bin/picker.sh"            "$HOME/.local/bin/picker.sh"
    chmod +x "$HOME/.local/bin/picker.sh"

    ok "Done."
}

main "$@"
