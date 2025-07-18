#!/bin/bash
set -euo pipefail

LOGFILE="/root/install_log.txt"
exec > >(tee -a "$LOGFILE") 2>&1

echo "=== Arch install script started at $(date) ==="

# 1. Локализация, часовой пояс, раскладка
echo "Setting timezone, locale and keyboard layout..."
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
hwclock --systohc

echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen

echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=us" > /etc/vconsole.conf

echo "archpc" > /etc/hostname

# 2. Настройка mkinitcpio для LUKS
echo "Configuring mkinitcpio hooks..."
sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect keyboard keymap modconf block encrypt filesystems fsck)/' /etc/mkinitcpio.conf
mkinitcpio -P

# 3. Установка и настройка GRUB
echo "Installing and configuring GRUB..."
UUID_ROOT=$(blkid -s UUID -o value /dev/nvme0n1p3)
if [ -z "$UUID_ROOT" ]; then
  echo "ERROR: Could not find UUID for /dev/nvme0n1p3"
  exit 1
fi

grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB

sed -i "s|^GRUB_CMDLINE_LINUX=.*|GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=$UUID_ROOT:cryptroot root=/dev/mapper/cryptroot\"|" /etc/default/grub

grub-mkconfig -o /boot/grub/grub.cfg

# 4. Создание пользователя и пароль root
echo "Setting root password..."
echo "root:1234" | chpasswd

echo "Creating user 'wk' and setting password..."
useradd -mG wheel wk
echo "wk:1234" | chpasswd

echo "Configuring sudoers for wheel group..."
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# 5. Включение служб NetworkManager и SDDM
echo "Enabling NetworkManager and SDDM services..."
systemctl enable NetworkManager
systemctl enable sddm

# 6. Установка драйверов Intel
echo "Installing Intel CPU and graphics drivers..."
pacman -S --noconfirm intel-ucode mesa vulkan-intel xf86-video-intel libva-intel-driver libva-utils

# 7. Установка AUR помощника paru
echo "Installing paru AUR helper..."
cd /home/wk
sudo -u wk git clone https://aur.archlinux.org/paru.git
chown -R wk:wk paru
cd paru
sudo -u wk makepkg -si --noconfirm

# 8. Установка Hyprland и зависимостей через paru
echo "Installing Hyprland and dependencies via paru..."
sudo -u wk paru -S --noconfirm hyprland waybar rofi dunst kitty thunar polkit-kde-agent pipewire pipewire-pulse wireplumber xdg-desktop-portal-hyprland xdg-desktop-portal wl-clipboard qt5-wayland qt6-wayland nwg-look

# 9. Настройка Hyprland конфигурации
echo "Setting up Hyprland config..."
sudo -u wk mkdir -p /home/wk/.config/hypr
sudo -u wk cp /usr/share/hyprland/examples/hyprland.conf /home/wk/.config/hypr/

echo "=== Arch install script completed successfully at $(date) ==="