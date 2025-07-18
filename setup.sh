# Creating the updated setup script content as a string based on the user's partition and login manager preferences

script_content = """#!/bin/bash
# Лог файл
LOGFILE="/var/log/arch-setup.log"
exec > >(tee -a "$LOGFILE") 2>&1

set -e

echo "=== Обновляем зеркала и устанавливаем базовые пакеты ==="
pacman -Syyu --noconfirm
pacman -S --noconfirm linux linux-firmware base base-devel \
    networkmanager grub efibootmgr intel-ucode \
    git pipewire wireplumber pipewire-audio pipewire-alsa pipewire-pulse \
    xdg-desktop-portal xdg-desktop-portal-hyprland \
    hyprland kitty thunar wofi chromium grim wl-clipboard \
    nano vim neofetch sudo \
    mesa libva-intel-driver vulkan-intel \
    ly

echo "=== Устанавливаем часовой пояс, локаль, hostname ==="
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
hwclock --systohc

echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen

echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=us" > /etc/vconsole.conf

echo "archpc" > /etc/hostname
cat <<EOF > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   archpc.localdomain archpc
EOF

echo "=== Устанавливаем загрузчик GRUB ==="
mkdir -p /boot/efi
mount /dev/sda1 /boot/efi
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

echo "=== Настраиваем SWAP ==="
mkswap /dev/sda2
swapon /dev/sda2

echo "=== Создаём пользователя ==="
echo "root:1234" | chpasswd
useradd -m -G wheel -s /bin/bash wk
echo "wk:1234" | chpasswd
echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/wheel

echo "=== Включаем службы ==="
systemctl enable NetworkManager
systemctl enable ly

echo "=== Установка завершена успешно ==="
"""

# Save script to a file
script_path = "/mnt/data/arch-setup.sh"
with open(script_path, "w") as f:
    f.write(script_content)

script_path
