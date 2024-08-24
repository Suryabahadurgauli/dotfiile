#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Print a message if an error occurs and where it happened
trap 'echo "Error occurred at line $LINENO"; exit 1;' ERR

# Detect the current username
USERNAME=$(whoami)

# Update sources list by replacing 'bookworm' with 'trixie'
sudo sed -i 's/bookworm/trixie/g' /etc/apt/sources.list

# Update the package lists
sudo apt update

# Upgrade the system with the new distribution
sudo DEBIAN_FRONTEND=noninteractive apt dist-upgrade -y

# Install necessary packages including xorg, i3-wm, alacritty, zsh, git, wget, curl, fonts-noto-color-emoji, polybar, and rofi
sudo apt install -y xorg i3-wm alacritty zsh zsh-common zsh-autosuggestions zsh-syntax-highlighting nvim network-manager git wget curl fonts-noto-color-emoji polybar rofi unzip

# Function to download and install fonts
install_font() {
    local FONT_URL=$1
    local FONT_DIR=$2
    local TEMP_FILE="/tmp/$(basename $FONT_URL)"

    # Create the directory for the font
    sudo mkdir -p $FONT_DIR

    # Download the font zip file
    wget -O $TEMP_FILE $FONT_URL

    # Extract the font zip file to the fonts directory
    sudo unzip $TEMP_FILE -d $FONT_DIR

    # Clean up the font zip file
    rm $TEMP_FILE
}

# Download and install JetBrains Mono font
install_font "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip" "/usr/share/fonts/JetBrainsMono"

# Download and install Hack font
install_font "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/Hack.zip" "/usr/share/fonts/Hack"

# Download and install Fira Code font
install_font "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/FiraCode.zip" "/usr/share/fonts/FiraCode"

# Download and install Meslo font
install_font "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/Meslo.zip" "/usr/share/fonts/Meslo"

# Update the font cache
sudo fc-cache -fv

# Change the default shell to zsh
chsh -s $(which zsh)

# Set up automatic login for tty1
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d

# Create an override configuration file for getty@tty1
cat <<EOF | sudo tee /etc/systemd/system/getty@tty1.service.d/override.conf
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $USERNAME --noclear %I \$TERM
EOF

# Reload systemd configuration and restart getty@tty1
sudo systemctl daemon-reload
sudo systemctl restart getty@tty1

# Delete all files and folders from the home directory
echo "Deleting all files and folders from the home directory..."
rm -rf /home/$USERNAME/* /home/$USERNAME/.[!.]* /home/$USERNAME/..?*

# Clone the dotfiles repository
echo "Cloning dotfiles repository..."
git clone https://github.com/Suryabahadurgauli/dotfile.git /home/$USERNAME/dotfile

# Clone the wallpapers repository
echo "Cloning wallpapers repository..."
git clone https://gitlab.com/dwt1/wallpapers.git /home/$USERNAME/wallpapers

# Install Google Chrome
echo "Installing Google Chrome..."
wget -O /tmp/google-chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt install -y /tmp/google-chrome.deb
rm /tmp/google-chrome.deb

# Function to check and stop a service if it exists
stop_service() {
    local service_name=$1
    if systemctl list-units --type=service --all | grep -q "${service_name}.service"; then
        echo "Stopping and disabling ${service_name} service..."
        sudo systemctl stop "${service_name}.service" || echo "Failed to stop ${service_name}.service"
        sudo systemctl disable "${service_name}.service" || echo "Failed to disable ${service_name}.service"
    else
        echo "${service_name}.service is not loaded or does not exist."
    fi
}

# Disable services related to ifupdown
stop_service "networking"
stop_service "ifupdown"

# Remove ifupdown
sudo apt remove --purge -y ifupdown

# Reboot the system
echo "Rebooting the system..."
sleep 5
sudo reboot
