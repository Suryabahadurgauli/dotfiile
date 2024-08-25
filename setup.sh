#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Print a message if an error occurs and where it happened
trap 'echo "Error occurred at line $LINENO"; exit 1;' ERR

# Function to execute commands with sudo using the provided password
run_sudo() {
    echo "$PASSWORD" | sudo -S "$@"
}

# Prompt for the root password
echo -n "Enter the root password: "
read -s PASSWORD
echo

# Detect the current username
USERNAME=$(whoami)

# Print the detected username and ask for confirmation
echo "Detected username: $USERNAME"
read -p "Is this username correct? (yes/no): " confirmation

if [[ "$confirmation" != "yes" && "$confirmation" != "y" ]]; then
    echo "Exiting script."
    exit 1
fi

# Function to download and install fonts
install_font() {
    local FONT_URL=$1
    local FONT_DIR=$2
    local TEMP_FILE="/tmp/$(basename $FONT_URL)"
    local FONT_DIR_NAME=$(basename $FONT_DIR)

    # Check if the font directory already contains the fonts
    if [ -d "$FONT_DIR" ] && [ "$(ls -A $FONT_DIR)" ]; then
        echo "$FONT_DIR already exists and is not empty. Skipping installation."
        return
    fi

    # Check if the font file already exists in /tmp
    if [ -f "$TEMP_FILE" ]; then
        echo "$TEMP_FILE already exists. Skipping download."
    else
        # Download the font zip file
        echo "Downloading $FONT_URL..."
        wget -O $TEMP_FILE $FONT_URL
    fi

    # Extract the font zip file to the fonts directory
    if [ -f "$TEMP_FILE" ]; then
        echo "Extracting $TEMP_FILE to $FONT_DIR..."
        run_sudo unzip -o $TEMP_FILE -d $FONT_DIR
        # Clean up the font zip file
        rm $TEMP_FILE
    fi
}

# Update sources list by replacing 'bookworm' with 'trixie'
run_sudo sed -i 's/bookworm/trixie/g' /etc/apt/sources.list

# Update the package lists
run_sudo apt update

# Upgrade the system with the new distribution
run_sudo DEBIAN_FRONTEND=noninteractive apt dist-upgrade -y

# Install necessary packages including xorg, i3-wm, alacritty, zsh, git, wget, curl, fonts-noto-color-emoji, polybar, and rofi
run_sudo apt install -y xorg i3 alacritty zsh zsh-common zsh-autosuggestions zsh-syntax-highlighting neovim network-manager git wget curl fonts-noto-color-emoji polybar feh rofi unzip command-not-found

# Download and install fonts
install_font "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip" "/usr/share/fonts/JetBrainsMono"
install_font "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/Hack.zip" "/usr/share/fonts/Hack"
install_font "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/FiraCode.zip" "/usr/share/fonts/FiraCode"
install_font "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/Meslo.zip" "/usr/share/fonts/Meslo"

# Update the font cache
run_sudo fc-cache -fv

# Change the default shell to zsh for the current user
run_sudo chsh -s $(which zsh) $USERNAME

# Change directory to home
echo "Changing home directory"
cd /home/$USERNAME

# Delete all files and folders from the home directory
echo "Deleting all files and folders from the home directory..."
rm -rf /home/$USERNAME/* /home/$USERNAME/.[!.]* /home/$USERNAME/..?*

# Clone the dotfiles repository
echo "Cloning dotfiles repository..."
git clone https://github.com/Suryabahadurgauli/dotfiile.git /home/$USERNAME/

# Move dotfiles to the home directory
#mv /home/$USERNAME/dotfiile/* /home/$USERNAME/

# Clone the wallpapers repository
echo "Cloning wallpapers repository..."
git clone https://gitlab.com/dwt1/wallpapers.git /home/$USERNAME/wallpapers

# Install Google Chrome
echo "Installing Google Chrome..."
wget -O /tmp/google-chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
run_sudo apt install -y /tmp/google-chrome.deb
rm /tmp/google-chrome.deb

# Function to check and stop a service if it exists
stop_service() {
    local service_name=$1
    if systemctl list-units --type=service --all | grep -q "${service_name}.service"; then
        echo "Stopping and disabling ${service_name} service..."
        run_sudo systemctl stop "${service_name}.service" || echo "Failed to stop ${service_name}.service"
        run_sudo systemctl disable "${service_name}.service" || echo "Failed to disable ${service_name}.service"
    else
        echo "${service_name}.service is not loaded or does not exist."
    fi
}

# Disable services related to ifupdown
stop_service "networking"
stop_service "ifupdown"

# Remove ifupdown
run_sudo apt remove --purge -y ifupdown
run_sudo mv /etc/network/interfaces /etc/network/interfaces.bak

# Set up automatic login for tty1
run_sudo mkdir -p /etc/systemd/system/getty@tty1.service.d

# Create or update an override configuration file for getty@tty1
OVERRIDE_CONF="/etc/systemd/system/getty@tty1.service.d/override.conf"
if [ -f "$OVERRIDE_CONF" ]; then
    if grep -q "ExecStart=-/sbin/agetty --autologin $USERNAME --noclear %I \$TERM" "$OVERRIDE_CONF"; then
        echo "$OVERRIDE_CONF already contains the desired configuration. Skipping."
    else
        echo "Updating $OVERRIDE_CONF with new configuration."
        cat <<EOF | run_sudo tee "$OVERRIDE_CONF"
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $USERNAME --noclear %I \$TERM
EOF
    fi
else
    echo "Creating $OVERRIDE_CONF with the desired configuration."
    cat <<EOF | run_sudo tee "$OVERRIDE_CONF"
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $USERNAME --noclear %I \$TERM
EOF
fi
run_sudo systemctl restart NetworkManager
sleep 10
echo
echo "Enter the Golden_network Password : " $WIFI_PASSWORD
nmcli device wifi connect Golden_network password $WIFI_PASSWORD

# Reload systemd configuration and restart getty@tty1
run_sudo systemctl daemon-reload
run_sudo systemctl restart getty@tty1
