#!/bin/bash
########################
# Author: Rocklin K S
# Date: 13/08/2024
# This script makes my config to autinstall
# Version: v1
############################


set -exo  pipefail
#Check if yay is installed
if ! command -v yay &> /dev/null; then
    sudo pacman -S yay --noconfirm
fi

# Function to check and add chaotic-aur repo
if ! grep -q "chaotic-aur" /etc/pacman.conf; then
    sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
    sudo pacman-key --lsign-key 3056513887B78AEB
    sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' --noconfirm
    sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' --noconfirm
fi

PACMAN="/etc/pacman.conf"
CHAOTIC="[chaotic-aur]"
INCLUDE_LINE="Include = /etc/pacman.d/chaotic-mirrorlist"

# Check if the section already exists in the file
if ! grep -q "$CHAOTIC" "$PACMAN"; then
    # Add the section to the end of the file
    echo -e "\n$CHAOTIC\n$INCLUDE_LINE" >> "$PACMAN"
    echo "Added $CHAOTIC and $INCLUDE_LINE to $PACMAN."
else
    echo "$CHAOTIC already exists in $PACMAN."
fi


sudo pacman -Syu --noconfirm
# Define the list of packages to install
packages=(
    zramswap preload python-dbus auto-cpufreq
    xfce4-panel polkit-gnome xfdesktop blueman
    xfce4-settings xfce4-power-manager xfce4-docklike-plugin
    bc openbox obconf playerctl picom parcellite
    numlockx rofi polybar lxappearance betterlockscreen
    zsh zsh-syntax-highlighting zsh-autosuggestions
   zsh-history-substring-search zsh-completions
)

# Install the packages if they are not already installed
for package in "${packages[@]}"; do
    if ! pacman -Q "$package" &> /dev/null; then
        sudo pacman -S "$package" --noconfirm
    else
        echo "$package is already installed. Skipping."
    fi
done

##Services to Enbale
sudo systemctl enable --now bluetooth
sudo systemctl enable --now preload

# Copy the backlight rules file, forcing the overwrite
sudo cp -Rf udev/rules.d/90-backlight.rules /etc/udev/rules.d/

# Define the path to the udev rules file
RULES_FILE="/etc/udev/rules.d/90-backlight.rules"
CURRENT_USER=$(whoami)
sudo sed -i "s/\$USER/$CURRENT_USER/g" "$RULES_FILE"

# Copy the networkmanager_dmenu file, forcing the overwrite
sudo cp -Rf usr/bin/networkmanager_dmenu /usr/bin/
sudo chmod +x /usr/bin/networkmanager_dmenu

mkdir -p Fonts
tar -xzvf Fonts.tar.gz -C Fonts
sudo cp -Rf Fonts/ /usr/share/fonts/
sudo fc-cache -fv

default_user=$(getent passwd 1000 | cut -d: -f1)
config_dir="/home/$default_user/.config"
home_dir="/home/$default_user"

# Create the destination directory if it doesn't exist
sudo -u "$default_user" mkdir -p "$config_dir"

# Copy the directories
sudo -u "$default_user" cp -Rf config/dunst config/networkmanager-dmenu config/openbox config/polybar config/xfce4 "$config_dir/"

# Change permissions for polybar scripts
sudo -u "$default_user" chmod +x "$config_dir/polybar/scripts/"*

# Create the zsh directory and extract the contents of zsh.tar.gz
mkdir -p zsh
tar -xzvf zsh.tar.gz -C zsh
sudo -u "$default_user" cp -Rf zsh/.bashrc "$home_dir/.bashrc"
sudo -u "$default_user" cp -Rf zsh/.zshrc "$home_dir/.zshrc"
sudo -u "$default_user" cp -Rf cache/* "$home_dir/.cache/"


SYSTEM_CONFIG="$home_dir/.config/polybar/system.ini"
POLYBAR_CONFIG="$home_dir/.config/polybar/config.ini"

# Get the active Ethernet and Wi-Fi interfaces
ETHERNET=$(ip link | awk '/state UP/ && !/wl/ {print $2}' | tr -d :)
WIFI=$(ip link | awk '/state UP/ && /wl/ {print $2}' | tr -d :)

# Check if Wi-Fi is active
if [ -n "$WIFI" ]; then
    echo "Using Wi-Fi interface: $WIFI"
    # Replace wlan0 with the actual Wi-Fi interface name in system.ini
    sed -i "s/sys_network_interface = wlan0/sys_network_interface = $WIFI/" "$SYSTEM_CONFIG"
    
# Check if Ethernet is active
elif [ -n "$ETHERNET" ]; then
    echo "Using Ethernet interface: $ETHERNET"
    # Replace wlan0 with the Ethernet interface name in system.ini
    sed -i "s/sys_network_interface = wlan0/sys_network_interface = $ETHERNET/" "$SYSTEM_CONFIG"
    
    # Replace 'network' with 'ethernet' in config.ini
    sed -i "s/network/ethernet/g" "$POLYBAR_CONFIG"

else
    echo "No active network interfaces found."
fi
chmod u+rw /sys/class/backlight/intel_backlight/brightness
