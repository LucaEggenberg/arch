Playbook for setting up Arch to my liking.

# Usage

## Base installation

https://wiki.archlinux.org/title/Installation_guide

### 1.set keyboard 
```bash
loadkeys de_CH-latin1
```

### 2. update clock 
```bash 
timedatectl 
```

### 3. partition disk 
| Partition | Type | Suggested size |
| -------- | ------- | ------- |
| boot  | EFI System | 1G |
| swap  | Linux swap | 4G-8G |
| swap  | Linux filesystem | remainder |

```bash
cfdisk
``` 

### 4. format partition
root:
```bash
mkfs.ext4 /dev/root_partition
```
efi: 
```bash
mkfs.fat -F 32 /dev/efi_partition
```
swap:
```bash
mkswap /dev/swap_partition
```

### 5. mount filesystem
root: 
```bash
mount /dev/root_partition /mnt
```
efi:
```bash
mount --mkdir /dev/efi_partition /mnt/boot
```
swap:
```bash
swapon  /dev/swap_partition
```

### 6. install essentials 
```bash
pacstrap /mnt base linux linux-firmware grub efibootmgr networkmanager git vi nano sudo
```

### 7. base configuration
Fstab:
```bash
genfstab -U /mnt >> /mnt/etc/fstab
```

Enter Chroot:
```bash
arch-chroot /mnt
```
Set timezone:
```bash
ln -sf /usr/share/zoneinfo/Europe/Zurich /etc/localtime
```
Sync clock: 
```bash
hwclock --systohc
```
Set locale:
```bash
vi /etc/locale.gen # uncomment 'eng_US.UTF-8'
```
Set vconsole layout:
```bash
echo KEYMAP=de_CH-latin1 >> /etc/vconsole.conf
```
Set network-hostname:
```bash
echo yourHostName >> /etc/hostname
```
Initramfs:
```bash 
mkinitcpio -P
```
Set root passwd:
```bash
passwd
```
Add non-Root user:
```bash
useradd -m -G wheel,audio,video,input,storage -s /bin/bash yourusername
passwd yourusername
```
enable sudo for wheel group:
```bash
visudo # uncomment '%wheel ALL=(ALL:ALL) ALL'
```
Setup and configure bootloader:
```bash
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB

grub-mkconfig -o /boot/grub/grub.cfg
```

### 9. Exit Chroot 
```bash
exit
```

### 10. unmount 
```bash
umount -R /mnt
```

### 11. Reboot
```bash
reboot now
```

### 12. Enable Networkmanager 
```bash
sudo systemctl enable --now NetworkManager
```

## Getting system ready
