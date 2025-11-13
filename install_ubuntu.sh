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

# Check if running on Ubuntu
if ! grep -q "Ubuntu" /etc/os-release; then
    log_error "This script is designed for Ubuntu. Use install_fedora.sh for Fedora."
    exit 1
fi

log_info "Starting installation on Ubuntu..."

# Update system
log_info "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install prerequisites
log_info "Installing prerequisites..."
sudo apt install -y curl wget gnupg2 software-properties-common apt-transport-https ca-certificates

# Install zsh
log_info "Installing zsh..."
sudo apt install -y zsh

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
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
rm -f packages.microsoft.gpg

# Add Google repository for Chrome
log_info "Adding Google repository for Chrome..."
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
sudo sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list'

# Update package lists after adding repositories
sudo apt update

# Install Java (OpenJDK 17)
log_info "Installing Java (OpenJDK 17)..."
sudo apt install -y openjdk-17-jdk

# Install Golang
log_info "Installing Golang..."
sudo apt install -y golang-go

# Install Rust using rustup (recommended for latest version)
log_info "Installing Rust using rustup..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"

# Install VS Code
log_info "Installing VS Code..."
sudo apt install -y code

# Install Google Chrome
log_info "Installing Google Chrome..."
sudo apt install -y google-chrome-stable

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

# Install Cursor (download and install deb package)
log_info "Installing Cursor code editor..."
wget -O cursor.deb "https://api2.cursor.sh/updates/download/golden/linux-x64-deb/cursor/2.0"
sudo dpkg -i cursor.deb
sudo apt install -f -y  # Fix any missing dependencies
rm cursor.deb

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
