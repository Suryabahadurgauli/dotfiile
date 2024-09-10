#!/bin/sh
run_sudo(){
	echo "$PASS" | sudo -S "$@"
}

echo -n "Enter the root password"
read -s PASS

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

install_font "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip" "/usr/share/fonts/JetBrainsMono"
install_font "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/Hack.zip" "/usr/share/fonts/Hack"
install_font "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/FiraCode.zip" "/usr/share/fonts/FiraCode"
install_font "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/Meslo.zip" "/usr/share/fonts/Meslo"
install_font "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/NerdFontsSymbolsOnly.zip" "/usr/share/fonts/NerdFontsSymbolsOnly"
install_font "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/IosevkaTermSlab.zip" "/usr/share/fonts/IosevkaTermSlab"

# Update the font cache
run_sudo fc-cache -fv
