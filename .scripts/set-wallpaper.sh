#!/bin/bash

# Directory containing the wallpapers
WALLPAPER_DIR="$HOME/wallpapers"

# Select a random wallpaper
RANDOM_WALLPAPER=$(find "$WALLPAPER_DIR" -type f -name '*.jpg' | shuf -n 1)

# Set the wallpaper using feh (you can replace this with another wallpaper setter if you prefer)
feh --bg-scale "$RANDOM_WALLPAPER"
