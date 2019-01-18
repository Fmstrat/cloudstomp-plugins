#!/bin/bash

sleep 5
export DEBIAN_FRONTEND=noninteractive

### Workaround: Pre-update /etc/default/grub and remove /boot/grub/menu.lst to avoid 'file changed' prompts from blocking completion of unattended update process
sudo patch /etc/default/grub <<'EOF'
10c10
< GRUB_CMDLINE_LINUX_DEFAULT="console=tty1 console=ttyS0"
---
> GRUB_CMDLINE_LINUX_DEFAULT="console=tty1 console=ttyS0 nvme.io_timeout=4294967295"
19c19
< GRUB_TERMINAL=console
---
> #GRUB_TERMINAL=console
EOF
sudo rm /boot/grub/menu.lst

sudo apt-get update && sudo apt-get install -y screen python-pip gocryptfs build-essential p7zip-full linux-image-extra-virtual libelf-dev

### Workaround part 2: re-generate /boot/grub/menu.lst
/usr/sbin/update-grub-legacy-ec2 -y

echo "blacklist nouveau" | sudo tee /etc/modprobe.d/blacklist-nouveau.conf
echo "blacklist lbm-nouveau" | sudo tee -a /etc/modprobe.d/blacklist-nouveau.conf
echo "options nouveau modeset=0" | sudo tee -a /etc/modprobe.d/blacklist-nouveau.conf
echo "alias nouveau off" | sudo tee -a /etc/modprobe.d/blacklist-nouveau.conf
echo "alias lbm-nouveau off" | sudo tee -a /etc/modprobe.d/blacklist-nouveau.conf
echo options nouveau modeset=0 | sudo tee -a /etc/modprobe.d/nouveau-kms.conf
sudo update-initramfs -u
sudo apt-get clean
pip install awscli
