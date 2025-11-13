#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on Fedora
if ! grep -q "Fedora" /etc/os-release; then
    log_error "This script is designed for Fedora. Use install_ubuntu.sh for Ubuntu."
    exit 1
fi

log_info "Starting installation on Fedora..."

# Update system
log_info "Updating system packages..."
sudo dnf update -y

# Install prerequisites
log_info "Installing prerequisites..."
sudo dnf install -y curl wget gnupg2 dnf-plugins-core

# Install zsh
log_info "Installing zsh..."
sudo dnf install -y zsh

# Install oh-my-zsh (unattended)
log_info "Installing oh-my-zsh..."
RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install oh-my-posh
log_info "Installing oh-my-posh..."
curl -s https://ohmyposh.dev/install.sh | bash -s -- -d ~/.local/bin

# Configure zsh and oh-my-posh
log_info "Setting zsh as default shell..."
sudo chsh -s "$(which zsh)" "$USER"

log_info "Configuring oh-my-posh in .zshrc..."
ZSHRC="${HOME}/.zshrc"
if [ ! -f "$ZSHRC" ]; then
    touch "$ZSHRC"
fi

# Add oh-my-posh to PATH if not already present
if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$ZSHRC"; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$ZSHRC"
fi

# Initialize oh-my-posh if not already present
if ! grep -q 'eval "$(oh-my-posh init zsh)"' "$ZSHRC"; then
    echo 'eval "$(oh-my-posh init zsh)"' >> "$ZSHRC"
fi

# Add Microsoft repository for VS Code
log_info "Adding Microsoft repository for VS Code..."
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'

# Add Google repository for Chrome
log_info "Adding Google repository for Chrome..."
sudo dnf config-manager --set-enabled google-chrome
sudo dnf install -y fedora-workstation-repositories
sudo dnf config-manager --set-enabled google-chrome

# Install Java (OpenJDK 17)
log_info "Installing Java (OpenJDK 17)..."
sudo dnf install -y java-17-openjdk-devel

# Install Golang
log_info "Installing Golang..."
sudo dnf install -y golang

# Install Rust using rustup (recommended for latest version)
log_info "Installing Rust using rustup..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"

# Install VS Code
log_info "Installing VS Code..."
sudo dnf install -y code

# Install Google Chrome
log_info "Installing Google Chrome..."
sudo dnf install -y google-chrome-stable

# Install NVM and Node.js
log_info "Installing NVM and Node.js..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
nvm install 24
log_info "Node.js version: $(node -v)"
log_info "npm version: $(npm -v)"

# Install Deno
log_info "Installing Deno..."
curl -fsSL https://deno.land/install.sh | sh

# Install Bun
log_info "Installing Bun..."
curl -fsSL https://bun.sh/install | bash

# Install uv (Python)
log_info "Installing uv(python)"
curl -LsSf https://astral.sh/uv/install.sh | sh


# Install Cursor (download and install rpm package)
log_info "Installing Cursor code editor..."
wget -O cursor.rpm "https://api2.cursor.sh/updates/download/golden/linux-x64-rpm/cursor/2.0"
sudo dnf install -y cursor.rpm
rm cursor.rpm

# Install helium-installer script
log_info "Running helium-installer script..."
curl -fsSL https://raw.githubusercontent.com/ni3rav/helium-installer/main/install.sh | bash

# Install Brave browser
log_info "Installing Brave browser..."
curl -fsS https://dl.brave.com/install.sh | sh

log_info "Installation completed successfully!"
log_info "You may need to restart your shell or source your ~/.bashrc to use some tools like nvm, rust, etc."
log_info "Installed tools:"
log_info "  - zsh (set as default shell)"
log_info "  - oh-my-zsh"
log_info "  - oh-my-posh (configured in ~/.zshrc)"
log_info "  - Node.js $(node -v) with npm $(npm -v)"
log_info "  - Deno $(deno --version 2>/dev/null || echo 'restart shell to check')"
log_info "  - Bun $(bun --version 2>/dev/null || echo 'restart shell to check')"
log_info "  - Java $(java -version 2>&1 | head -n 1)"
log_info "  - Golang $(go version)"
log_info "  - Rust $(rustc --version 2>/dev/null || echo 'restart shell to check')"
log_info "  - VS Code"
log_info "  - Cursor"
log_info "  - Brave Browser"
log_info "  - Google Chrome"
