# Development Environment Setup

This repository contains an automated setup script for configuring your development environment. The script installs Zsh, Docker, Micro, and essential network tools like `nslookup` and `telnet`. It also sets up custom aliases and plugins for Zsh to enhance your productivity.

## Features

- Installs Zsh and Oh My Zsh
- Installs Docker and Docker Compose
- Installs Micro text editor
- Installs essential network tools (`nslookup`, `telnet`)
- Sets up Zsh plugins for syntax highlighting and autosuggestions
- Configures custom aliases for Docker, Kubernetes, and PostgreSQL commands
- Adds the current directory to the PATH

## Prerequisites

- A Linux-based system
- git

## Installation

1. Clone this repository to your local machine:

   ```bash
   git clone https://github.com/darbinyanalbert/server-setup-scripts.git
   cd server-setup-scripts
   ```

2. Make the installation script executable:

   ```bash
   chmod +x install.sh
   ```

3. Run the installation script:

   ```bash
   ./install.sh
   ```

4. Restart your terminal or run ``exec zsh`` to apply changes.
