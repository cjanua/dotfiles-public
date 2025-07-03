#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Installing packages...${NC}"

# Essential packages
packages=(
    "base-devel"
    "git"
    "neovim"
    "hyprland"
    "waybar"
    "rofi"
    "dunst"
    "alacritty"
    "starship"
    "fastfetch"
    "ttf-jetbrains-mono-nerd"
    "ttf-font-awesome"
    "pipewire"
    "pipewire-alsa"
    "pipewire-pulse"
    "wireplumber"
    "networkmanager"
    "bluez"
    "bluez-utils"
    "brightnessctl"
    "playerctl"
    "grim"
    "slurp"
    "swappy"
    "wl-clipboard"
)

# Install packages
sudo pacman -S --needed "${packages[@]}"

# Install yay if not present
if ! command -v yay &> /dev/null; then
    echo -e "${YELLOW}Installing yay...${NC}"
    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ~/dotfiles
fi

# AUR packages
aur_packages=(
    "waybar-hyprland-git"
    "sddm-git"
    "wlogout"
)

echo -e "${GREEN}Installing AUR packages...${NC}"
yay -S --needed "${aur_packages[@]}"

# Create necessary directories
echo -e "${GREEN}Creating config directories...${NC}"
mkdir -p ~/.config/{hypr,waybar,rofi,dunst,alacritty,nvim,fastfetch,starship}

# Create symlinks
echo -e "${GREEN}Creating symlinks...${NC}"
ln -sf "$PWD/.bashrc" ~/.bashrc
ln -sf "$PWD/hypr" ~/.config/
ln -sf "$PWD/waybar" ~/.config/
ln -sf "$PWD/rofi" ~/.config/
ln -sf "$PWD/dunst" ~/.config/
ln -sf "$PWD/alacritty" ~/.config/
ln -sf "$PWD/nvim" ~/.config/
ln -sf "$PWD/fastfetch" ~/.config/
ln -sf "$PWD/starship/starship.toml" ~/.config/

# Copy wallpapers
echo -e "${GREEN}Setting up wallpapers...${NC}"
mkdir -p ~/Pictures/wallpapers
cp -r wallpapers/* ~/Pictures/wallpapers/

# Enable services
echo -e "${GREEN}Enabling services...${NC}"
sudo systemctl enable NetworkManager
sudo systemctl enable bluetooth
sudo systemctl enable sddm

echo -e "${GREEN}Installation complete!${NC}"
echo -e "${YELLOW}Please reboot to start using Hyprland${NC}"
