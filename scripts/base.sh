#!/bin/bash

# Updating pacman keyring (uncomment if ISO has signature problems)
#sed -i '/\[options\]/a SigLevel = Never' /etc/pacman.conf
#pacman -Sy --noconfirm archlinux-keyring
#umount /etc/pacman.d/gnupg
pacman-key --init
pacman-key --populate
#pacman -Sy --noconfirm archlinux-keyring

# Create filesystems
mkfs.ext4 /dev/sda1
mkfs.ext4 /dev/sda3
mkswap /dev/sda2

# Label filesystems
e2label /dev/sda1 boot
e2label /dev/sda3 root
swaplabel -L swap /dev/sda2

# Do mounts and enable swap
mount /dev/sda3 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot
swapon /dev/sda2

# Search for best mirrors (uncomment if geomirror is failing)
#echo "Ranking mirrors (may take a while) . . ."
#reflector --verbose --age 6 --score 50 --number 10 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
#echo "Ranking mirrors done!"

# Install base and base-devel arch linux stuff
pacstrap /mnt base base-devel

# Generate fstab with mounts
genfstab -p /mnt >> /mnt/etc/fstab

# Enter in chroot and finish installation
arch-chroot /mnt << EOF
echo arch > /etc/hostname
ln -s /usr/share/zoneinfo/UTC /etc/localtime
sed -i 's/#en_US.UTF-8/en_US.UTF-8/g' /etc/locale.gen
locale-gen
echo LANG=en_US.UTF-8 > /etc/locale.conf
echo KEYMAP=us > /etc/vconsole.conf
sed -i 's/# %wheel ALL=(ALL:ALL) N/%wheel ALL=(ALL:ALL) N/g' /etc/sudoers
pacman -S --noconfirm dhcpcd grub linux openssh netctl openresolv virtualbox-guest-utils-nox
pacman -S --noconfirm less git vim man-db
systemctl enable sshd vboxservice
grub-install --target=i386-pc --recheck --debug /dev/sda
sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=1/g' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
cp /etc/netctl/examples/ethernet-dhcp /etc/netctl/enp0s3
sed -i 's/Interface=eth0/Interface=enp0s3/g' /etc/netctl/enp0s3
netctl enable enp0s3
pacman -Scc --noconfirm
useradd -m vagrant
echo vagrant:vagrant | chpasswd
usermod -a -G adm,disk,wheel,log,vboxsf vagrant

# yay
cd /home/vagrant
git clone https://aur.archlinux.org/yay-bin.git
chown -R vagrant:vagrant yay-bin
cd yay-bin
su vagrant makepkg
pacman -U --noconfirm yay-bin-*pkg.tar.zst
cd ..
rm -rf yay-bin

exit
EOF

# Do final sync
sync
