#!/bin/bash

# Set the repository directory to the current script's directory
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Define colors for output
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting installation of Zsh, Oh My Zsh, Docker, Micro, Docker Compose, and plugins...${NC}"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Update package lists and install dependencies
if command_exists apt; then
    sudo apt update
    sudo apt install -y curl git wget zsh dnsutils telnet
elif command_exists yum; then
    sudo yum install -y curl git wget zsh bind-utils telnet
elif command_exists dnf; then
    sudo dnf install -y curl git wget zsh bind-utils telnet
elif command_exists pacman; then
    sudo pacman -Sy --noconfirm curl git wget zsh inetutils
else
    echo "Unsupported package manager. Exiting."
    exit 1
fi

# Install Docker
if ! command_exists docker; then
    echo -e "${GREEN}Installing Docker...${NC}"
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    rm get-docker.sh
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker $USER
    newgrp docker
else
    echo -e "${GREEN}Docker is already installed.${NC}"
fi

# Install Docker Compose
if ! command_exists docker-compose; then
    echo -e "${GREEN}Installing Docker Compose...${NC}"
    sudo curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
else
    echo -e "${GREEN}Docker Compose is already installed.${NC}"
fi

# Install Micro
if ! command_exists micro; then
    echo -e "${GREEN}Installing Micro...${NC}"
    curl https://getmic.ro | bash
    sudo mv micro /usr/local/bin
else
    echo -e "${GREEN}Micro is already installed.${NC}"
fi

# Install Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo -e "${GREEN}Installing Oh My Zsh...${NC}"
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo -e "${GREEN}Oh My Zsh is already installed.${NC}"
fi

# Set Zsh as default shell
if [ "$SHELL" != "$(command -v zsh)" ]; then
    echo -e "${GREEN}Setting Zsh as the default shell...${NC}"
    sudo chsh -s $(which zsh) $(whoami)
fi

# Install Zsh plugins (zsh-syntax-highlighting and zsh-autosuggestions)
ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}

echo -e "${GREEN}Installing Zsh plugins...${NC}"
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
git clone https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_CUSTOM/plugins/zsh-autosuggestions"

# Add plugins to .zshrc
if ! grep -q "plugins=(git zsh-syntax-highlighting zsh-autosuggestions)" ~/.zshrc; then
    echo -e "${GREEN}Adding plugins to .zshrc...${NC}"
    sed -i 's/plugins=(git)/plugins=(git zsh-syntax-highlighting zsh-autosuggestions)/' ~/.zshrc
    sed -i 's/^ZSH_THEME=.*/ZSH_THEME="alanpeabody"/' ~/.zshrc
fi

# Add the repository to PATH in .zshrc
echo "Adding repository to PATH in .zshrc..."
echo "export PATH=\"\$PATH:$REPO_DIR\"" >> ~/.zshrc

# Add aliases to .zshrc
echo "Adding aliases to .zshrc..."
cat << 'EOF' >> ~/.zshrc

# Custom Aliases
alias redis-cli="redis-cli-docker"
alias psql="psql-docker"
alias pg_dump="pg_dump-docker"
alias pg_restore="pg_restore-docker"
alias d="docker"
alias dc="docker-compose"
alias k="kubectl"
alias kd="kubectl describe"
alias kg="kubectl get"
alias m="micro"

kns() {
    kubectl config set-context --current --namespace $1
}
EOF

echo -e "${GREEN}Installation complete. Please restart your terminal or run 'exec zsh' to apply changes.${NC}"
