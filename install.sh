#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting dotfiles setup with backup...${NC}"

# --- 1. Create Backup of Existing Configuration ---
echo -e "${YELLOW}Creating backup of existing ~/.config and .bashrc...${NC}"

BACKUP_TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
CONFIG_BACKUP_DIR="$HOME/.config_backup_$BACKUP_TIMESTAMP"
BASHRC_BACKUP_FILE="$HOME/.bashrc_backup_$BACKUP_TIMESTAMP"

# Backup ~/.config
if [ -d "$HOME/.config" ] || [ -L "$HOME/.config" ]; then
    mkdir -p "$CONFIG_BACKUP_DIR" || { echo -e "${RED}Failed to create backup directory: $CONFIG_BACKUP_DIR.${NC}"; exit 1; }
    echo -e "${GREEN}Backing up ~/.config to $CONFIG_BACKUP_DIR${NC}"
    # Use rsync to preserve permissions and handle symlinks correctly for backup
    rsync -a "$HOME/.config/" "$CONFIG_BACKUP_DIR/" || { echo -e "${RED}Failed to backup ~/.config.${NC}"; exit 1; }
else
    echo -e "${YELLOW}~/.config does not exist or is empty. No backup needed for ~/.config.${NC}"
fi

# Backup ~/.bashrc
if [ -f "$HOME/.bashrc" ] || [ -L "$HOME/.bashrc" ]; then
    echo -e "${GREEN}Backing up ~/.bashrc to $BASHRC_BACKUP_FILE${NC}"
    cp -p "$HOME/.bashrc" "$BASHRC_BACKUP_FILE" || { echo -e "${RED}Failed to backup ~/.bashrc.${NC}"; exit 1; }
else
    echo -e "${YELLOW} ~/.bashrc does not exist or is empty. No backup needed for .bashrc.${NC}"
fi

echo -e "${GREEN}Backup complete.${NC}"

# --- Package Installation (unchanged) ---
echo -e "${GREEN}Installing essential packages...${NC}"
packages=(
    "base-devel" "git" "neovim" "hyprland" "waybar" "rofi" "dunst"
    "alacritty" "starship" "fastfetch" "ttf-jetbrains-mono-nerd"
    "ttf-font-awesome" "pipewire" "pipewire-alsa" "pipewire-pulse"
    "wireplumber" "networkmanager" "bluez" "bluez-utils"
    "brightnessctl" "playerctl" "grim" "slurp" "swappy" "wl-clipboard"
    "fortune" "cowsay" "neofetch"
)
sudo pacman -S --needed "${packages[@]}" || { echo -e "${RED}Failed to install core packages.${NC}"; exit 1; }

# Install yay if not present
if ! command -v yay &> /dev/null; then
    echo -e "${YELLOW}Installing yay...${NC}"
    cd /tmp || { echo -e "${RED}Failed to change to /tmp directory.${NC}"; exit 1; }
    git clone https://aur.archlinux.org/yay.git || { echo -e "${RED}Failed to clone yay repository.${NC}"; exit 1; }
    cd yay || { echo -e "${RED}Failed to change to yay directory.${NC}"; exit 1; }
    makepkg -si --noconfirm || { echo -e "${RED}Failed to install yay.${NC}"; exit 1; }
    cd - || { echo -e "${RED}Failed to return to previous directory.${NC}"; exit 1; } # Return to original PWD
fi

# AUR packages
echo -e "${GREEN}Installing AUR packages...${NC}"
aur_packages=(
    "waybar-hyprland-git"
    "sddm-git"
    "wlogout"
)
yay -S --needed "${aur_packages[@]}" || { echo -e "${RED}Failed to install AUR packages.${NC}"; exit 1; }

# --- Core Symlinking Logic (from previous version) ---
echo -e "${GREEN}Creating symlinks for dotfiles...${NC}"

# Ensure ~/.config directory exists for symlink targets
mkdir -p "$HOME/.config" || { echo -e "${RED}Failed to create ~/.config directory.${NC}"; exit 1; }

# Get current directory where the script is run (your dotfiles repo)
DOTFILES_DIR="$PWD"

# Loop through all items (files and directories, including dotfiles) in the current directory
shopt -s dotglob # Include dotfiles in globbing
for item in "$DOTFILES_DIR"/* "$DOTFILES_DIR"/.[!.]*; do
    # Check if item exists (important for dotglob/nullglob cases)
    [ -e "$item" ] || continue

    ITEM_NAME=$(basename "$item")
    SOURCE_PATH="$item"
    TARGET_PATH=""

    # Skip known non-config items
    if [[ "$ITEM_NAME" == "wallpapers" ]] || \
       [[ "$ITEM_NAME" == "README.md" ]] || \
       [[ "$ITEM_NAME" == ".git" ]] || \
       [[ "$ITEM_NAME" == ".gitignore" ]] || \
       [[ "$ITEM_NAME" == ".bash_history" ]] || \
       [[ "$ITEM_NAME" == "install.sh" ]] || \
       [[ "$ITEM_NAME" == "${BASH_SOURCE[0]##*/}" ]]; then # Skips the script itself
        echo -e "${YELLOW}Skipping non-config item: $ITEM_NAME${NC}"
        continue
    fi

    # Determine target path
    if [[ "$ITEM_NAME" == ".bashrc" ]]; then
        TARGET_PATH="$HOME/.bashrc"
        echo -e "${GREEN}Processing .bashrc -> $TARGET_PATH${NC}"
    elif [[ -f "$SOURCE_PATH" ]] && [[ "$ITEM_NAME" == "starship.toml" ]]; then
        # Handle starship.toml if it's directly in the root of dotfiles
        TARGET_PATH="$HOME/.config/$ITEM_NAME"
        echo -e "${GREEN}Processing starship.toml -> $TARGET_PATH${NC}"
    else
        # All other items go into ~/.config/
        TARGET_PATH="$HOME/.config/$ITEM_NAME"
        echo -e "${GREEN}Processing $ITEM_NAME -> $TARGET_PATH${NC}"
    fi

    # Now, perform the robust symlinking
    if [ -n "$TARGET_PATH" ]; then # Ensure TARGET_PATH is set
        if [ -d "$TARGET_PATH" ] && ! [ -L "$TARGET_PATH" ]; then
            # If target is an existing real directory, remove it
            echo -e "${YELLOW}Removing existing directory at $TARGET_PATH${NC}"
            rm -rf "$TARGET_PATH" || { echo -e "${RED}Failed to remove $TARGET_PATH.${NC}"; exit 1; }
        elif [ -f "$TARGET_PATH" ] && ! [ -L "$TARGET_PATH" ]; then
            # If target is an existing real file, remove it
            echo -e "${YELLOW}Removing existing file at $TARGET_PATH${NC}"
            rm -f "$TARGET_PATH" || { echo -e "${RED}Failed to remove $TARGET_PATH.${NC}"; exit 1; }
        fi

        # Create the symlink
        ln -sf "$SOURCE_PATH" "$TARGET_PATH" || { echo -e "${RED}Failed to create symlink for $ITEM_NAME.${NC}"; exit 1; }
    fi

done
shopt -u dotglob # Turn off dotglob

# --- Wallpapers (unchanged) ---
echo -e "${GREEN}Setting up wallpapers...${NC}"
WALLPAPER_SOURCE_DIR="$DOTFILES_DIR/wallpapers"
WALLPAPER_TARGET_DIR="$HOME/Pictures/wallpapers"
if [ -d "$WALLPAPER_SOURCE_DIR" ]; then
    mkdir -p "$WALLPAPER_TARGET_DIR" || { echo -e "${RED}Failed to create wallpaper directory.${NC}"; exit 1; }
    cp -r "$WALLPAPER_SOURCE_DIR"/* "$WALLPAPER_TARGET_DIR/" || { echo -e "${RED}Failed to copy wallpapers.${NC}"; exit 1; }
else
    echo -e "${YELLOW}Warning: Wallpapers directory '$WALLPAPER_SOURCE_DIR' does not exist. Skipping wallpaper setup.${NC}"
fi

# --- Enable services (unchanged) ---
echo -e "${GREEN}Enabling services...${NC}"
sudo systemctl enable NetworkManager || { echo -e "${RED}Failed to enable NetworkManager.${NC}"; }
sudo systemctl enable bluetooth || { echo -e "${RED}Failed to enable bluetooth.${NC}"; }
sudo systemctl enable sddm || { echo -e "${RED}Failed to enable sddm.${NC}"; }

echo -e "${GREEN}Installation complete!${NC}"
echo -e "${YELLOW}Please reboot to start using Hyprland${NC}"