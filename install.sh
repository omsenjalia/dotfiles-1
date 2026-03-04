#!/bin/bash

# --- Configuration ---
PACKAGES_FILE="packages.txt"
DOTFILES_DIR_NAME="dotfiles"

# --- Functions ---

error() {
    echo -e "\e[31m[ERROR]\e[0m $1" >&2
    exit 1
}

info() {
    echo -e "\e[34m[INFO]\e[0m $1"
}

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root. Please run with sudo ./install.sh"
fi

# Check if packages.txt exists
if [[ ! -f "$PACKAGES_FILE" ]]; then
    error "$PACKAGES_FILE not found!"
fi

# Get username and password
read -p "Enter the username to create: " USERNAME
if [[ -z "$USERNAME" ]]; then
    error "Username cannot be empty"
fi

if id "$USERNAME" &>/dev/null; then
    info "User $USERNAME already exists."
else
    read -s -p "Enter the password for $USERNAME: " PASSWORD
    echo
    read -s -p "Confirm password: " PASSWORD_CONFIRM
    echo
    if [[ "$PASSWORD" != "$PASSWORD_CONFIRM" ]]; then
        error "Passwords do not match"
    fi

    # Create user with fish shell if available, otherwise bash
    if command -v fish &>/dev/null; then
        useradd -m -G wheel -s "$(command -v fish)" "$USERNAME"
    else
        # Install fish first as it's in the package list, but for now use bash
        useradd -m -G wheel -s /bin/bash "$USERNAME"
    fi

    echo "$USERNAME:$PASSWORD" | chpasswd
    info "User $USERNAME created and added to wheel group."
fi

# Configure sudo for wheel group
if [[ ! -f /etc/sudoers.d/wheel ]]; then
    echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/wheel
    chmod 440 /etc/sudoers.d/wheel
    info "Sudo configured for wheel group."
fi

# Essential packages for the installation process
info "Installing essential packages (base-devel, git, stow)..."
pacman -Syu --needed --noconfirm base-devel git stow

# Parse and install official packages
info "Installing official packages..."
OFFICIAL_PKGS=$(sed -n '/\[pacman\]/,/\[aur\]/p' "$PACKAGES_FILE" | grep -v '^\s*#' | grep -v '^\[.*\]' | awk '{print $1}' | xargs)
if [[ -n "$OFFICIAL_PKGS" ]]; then
    pacman -S --needed --noconfirm $OFFICIAL_PKGS
else
    info "No official packages to install."
fi

# Install yay if not present
if ! sudo -u "$USERNAME" command -v yay &>/dev/null; then
    info "Installing yay AUR helper..."
    sudo -u "$USERNAME" bash -c "
        cd /tmp
        rm -rf yay
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si --noconfirm
    "
else
    info "yay is already installed."
fi

# Parse and install AUR packages
info "Installing AUR packages..."
AUR_PKGS=$(sed -n '/\[aur\]/,$p' "$PACKAGES_FILE" | grep -v '^\s*#' | grep -v '^\[.*\]' | awk '{print $1}' | xargs)
if [[ -n "$AUR_PKGS" ]]; then
    sudo -u "$USERNAME" yay -S --needed --noconfirm $AUR_PKGS
else
    info "No AUR packages to install."
fi

# Setup Dotfiles
USER_HOME=$(eval echo "~$USERNAME")
TARGET_DOTFILES_DIR="$USER_HOME/$DOTFILES_DIR_NAME"

info "Setting up dotfiles in $TARGET_DOTFILES_DIR..."
if [[ ! -d "$TARGET_DOTFILES_DIR" ]]; then
    mkdir -p "$TARGET_DOTFILES_DIR"
fi

# Use rsync to copy files, excluding the script and git data
# -a: archive mode, -v: verbose, -u: skip files that are newer on the receiver
rsync -av --exclude='.git' --exclude='install.sh' --exclude='packages.txt' ./ "$TARGET_DOTFILES_DIR/"
chown -R "$USERNAME:$USERNAME" "$TARGET_DOTFILES_DIR"

# Stow the dotfiles
info "Stowing dotfiles..."
# We stow the entire dotfiles directory into the user's home.
# Since the dotfiles directory contains .config, .bashrc, etc.,
# stow will symlink ~/.config to ~/dotfiles/.config and so on.
sudo -u "$USERNAME" bash -c "
    cd \"$USER_HOME\"
    stow -v -R -t \"\$HOME\" \"$DOTFILES_DIR_NAME\"
"

# Enable services
info "Enabling system services..."
systemctl enable NetworkManager.service || info "NetworkManager service not found or already enabled."
systemctl enable bluetooth.service || info "Bluetooth service not found or already enabled."

# User services
info "Enabling user services..."
loginctl enable-linger "$USERNAME"
# Using a subshell to run as user with appropriate environment
sudo -u "$USERNAME" bash -c "
    export XDG_RUNTIME_DIR=/run/user/\$(id -u)
    systemctl --user enable pipewire.service pipewire-pulse.service wireplumber.service || true
"

info "Installation complete! Please log in as $USERNAME to start using your new system."
