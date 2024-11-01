#!/bin/bash

# Set the repository directory to the current script's directory
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Define colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Function to display a loading animation
loading_animation() {
    local pid=$1
    local delay=0.1
    local spin='|/-\'
    
    if [ -n "$pid" ] && ps -p $pid > /dev/null 2>&1; then
        echo -ne "${YELLOW}Please wait...${NC} "
        while ps -p $pid > /dev/null 2>&1; do
            for i in $(seq 0 3); do
                echo -ne "\r${YELLOW}Please wait... ${spin:i:1}${NC}"
                sleep $delay
            done
        done
        echo -ne "\r${GREEN}Done!${NC}           \n"
    else
        echo -e "${YELLOW}Loading...${NC}"
    fi
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function for logging messages
log_info() {
    echo -e "${GREEN}[INFO] ${1}${NC}"
}

# Function for logging warnings
log_warning() {
    echo -e "${YELLOW}[WARNING] ${1}${NC}"
}

# Function for logging errors
log_error() {
    echo -e "${RED}[ERROR] ${1}${NC}"
}

log_info "Starting installation of Zsh, Oh My Zsh, Docker, Micro, Docker Compose, and plugins..."


# Update package lists and install dependencies
if command_exists apt; then
    sudo apt update
    sudo apt install -y curl git wget zsh dnsutils telnet
elif command_exists yum; then
    sudo yum install -y curl git wget zsh bind-utils telnet
elif command_exists dnf; then
    sudo dnf install -y curl git wget zsh bind-utils telnet
elif command_exists pacman; then
    sudo pacman -Sy --noconfirm curl git wget zsh bind-tools inetutils
else
    log_error "Unsupported package manager. Exiting."
    exit 1
fi

# Install Docker
if ! command_exists docker; then
    log_info "Installing Docker..."
    
    if command_exists apt; then
        sudo apt update
        sudo apt install -y docker.io &
    elif command_exists yum; then
        sudo yum install -y docker &
    elif command_exists dnf; then
        sudo dnf install -y docker &
    elif command_exists pacman; then
        sudo pacman -Sy --noconfirm docker &
    else
        echo "Unsupported package manager. Exiting."
        exit 1
    fi

    # Show loading animation while installing Docker
    loading_animation $!

    # Start and enable Docker if systemd is available
    if pidof systemd >/dev/null; then
        sudo systemctl start docker
        sudo systemctl enable docker
        sudo usermod -aG docker $USER
        newgrp docker
    else
        log_info "System does not use systemd. Please start Docker manually if required."
    fi
else
    log_info "Docker is already installed."
fi

# Install Docker Compose
if ! command_exists docker-compose; then
    log_info "Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
else
    log_info "Docker Compose is already installed."
fi

# Install Micro
if ! command_exists micro; then
    log_info "Installing Micro..."
    curl https://getmic.ro | bash
    sudo mv micro /usr/local/bin
else
    log_info "Micro is already installed."
fi

# Install Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    log_info "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    log_info "Oh My Zsh is already installed."
fi

# Set Zsh as default shell
if [ "$SHELL" != "$(command -v zsh)" ]; then
    log_info "Setting Zsh as the default shell..."
    sudo chsh -s $(which zsh) $(whoami)
fi

# Install Zsh plugins (zsh-syntax-highlighting and zsh-autosuggestions)
ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}

log_info "Installing Zsh plugins..."
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
git clone https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_CUSTOM/plugins/zsh-autosuggestions"

# Add plugins to .zshrc
if ! grep -q "plugins=(git zsh-syntax-highlighting zsh-autosuggestions)" ~/.zshrc; then
    log_info "Adding plugins to .zshrc..."
    sed -i 's/plugins=(git)/plugins=(git zsh-syntax-highlighting zsh-autosuggestions)/' ~/.zshrc
    sed -i 's/^ZSH_THEME=.*/ZSH_THEME="alanpeabody"/' ~/.zshrc
fi

# Add the repository to PATH in .zshrc
log_info "Adding repository to PATH in .zshrc..."
echo "export PATH=\"\$PATH:$REPO_DIR\"" >> ~/.zshrc

# Add aliases to .zshrc
log_info "Adding aliases to .zshrc..."
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

log_info "Installation complete! Please restart your terminal or run 'exec zsh' to apply changes."
