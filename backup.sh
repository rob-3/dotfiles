#!/bin/bash
# vim: tw=0

echo "Which device should I use?"
read device
echo Decrypting /dev/${device}...
if sudo cryptsetup open /dev/${device} ${device}-cryptdrive ; then
	echo Done!
else
	echo Decryption failed!
	exit 1
fi

echo Mounting /dev/mapper/${device}-cryptdrive to /mnt...
if sudo mount /dev/mapper/${device}-cryptdrive /mnt ; then
	echo Mounted!
else
	echo Mounting failed!
	echo Closing /dev/mapper/cryptdrive...
	sudo cryptsetup close ${device}-cryptdrive
	exit 1
fi

echo Making directories...
sudo mkdir -p /mnt/backups/desktop/home
sudo mkdir -p /mnt/backups/desktop/etc
echo Done!
echo Backing up...
if pacman -Qqe > ~/installed-packages && sudo rsync -avzP --delete /home/daystrom/ /mnt/backups/desktop/home/ --exclude=.cache --delete-excluded && sudo rsync -avzP --delete /etc/ /mnt/backups/desktop/etc/ && rm ~/installed-packages ; then
	echo Done!
else
	echo Backup aborted!
fi
echo Unmounting...
sudo umount /mnt
echo Done!
echo Closing /dev/mapper/cryptdrive...
sudo cryptsetup close ${device}-cryptdrive
echo Done!
echo Ejecting /dev/sdb...
sudo eject /dev/$device
echo Done!
