#!/bin/bash
LOG="/var/log/arch-setup.log"
exec > >(tee -a "$LOG") 2>&1

echo "[*] Обновление ключей и базы..."
pacman -Sy --noconfirm archlinux-keyring

echo "[*] Установка базовых пакетов..."
pacman -S --noconfirm base base-devel linux linux-firmware linux-headers \
    networkmanager grub efibootmgr sudo nano git reflector intel-ucode \
    pipewire pipewire-pulse wireplumber alsa-utils sof-firmware \
    xorg-server mesa vulkan-intel xf86-video-intel ly

echo "[*] Генерация fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

echo "[*] Настройка локали и времени..."
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
hwclock --systohc
sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=us" > /etc/vconsole.conf

echo "[*] Настройка hostname и hosts..."
echo "archpc" > /etc/hostname
cat <<EOF > /etc/hosts
127.0.0.1 localhost
::1       localhost
127.0.1.1 archpc.localdomain archpc
EOF

echo "[*] Включение swap..."
mkswap /dev/sda2
swapon /dev/sda2

echo "[*] Установка загрузчика grub (EFI)..."
mkdir -p /boot/EFI
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

echo "[*] Включение служб..."
systemctl enable NetworkManager
systemctl enable ly

echo "[*] Добавление пользователя..."
useradd -m -G wheel -s /bin/bash wk
echo "wk:1234" | chpasswd
echo "root:1234" | chpasswd

echo "[*] Разрешение sudo для wheel..."
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

echo "[*] Установка Hyprland и зависимостей..."
pacman -S --noconfirm hyprland kitty waybar wofi thunar grim slurp wl-clipboard \
    qt5-wayland qt6-wayland qt5ct qt6ct xdg-desktop-portal-hyprland xdg-utils \
    xdg-user-dirs

echo "[*] Установка завершена. Проверьте лог: $LOG"
