#!/bin/bash

# Remove chroot bash_history and ssh keys
rm -f /mnt/root/.bash_history
rm -f /mnt/home/vagrant/.bash_history
rm -f /mnt/etc/ssh/ssh_host_*

# Force sync
sync
umount -R /mnt
sync
