cd `dirname $0`

THISDIR=`dirname $0`

echo " softboiling monster-mesh.img "

./box-mount

#the code bellow softboils the operating system to reduce the chance
#of a sdcard write falure on unexpected power off we do this by building
#fstab mounts that use the ramdisk for often written files, that are save to delete on power off


# turns out on recent versions (systemd?) that /run is not safe to move to ram.
#tmpfs            /var/run       tmpfs   defaults,noatime,nosuid,size=64m    0 0


#use these for card booting
sudo tee root/etc/fstab.card >/dev/null <<EOF

proc            /proc           proc    defaults          0       0
/dev/mmcblk0p1  /boot           vfat    defaults,noatime  0       2
/dev/mmcblk0p2  /               ext4    defaults,noatime  0       1

tmpfs            /tmp           tmpfs   defaults,noatime,nosuid,size=64m    0 0
tmpfs            /var/lib/dhcp  tmpfs   defaults,noatime,nosuid,size=64m    0 0
tmpfs            /var/spool     tmpfs   defaults,noatime,nosuid,size=64m    0 0
tmpfs            /var/lock      tmpfs   defaults,noatime,nosuid,size=64m    0 0

#/dev/sda2  /               ext4    defaults,noatime  0       1

EOF


#use these for qemu booting
sudo tee root/etc/fstab.qemu >/dev/null <<EOF

proc             /proc           proc    defaults          0       0
#/dev/mmcblk0p1  /boot           vfat    defaults,noatime  0       2
#/dev/mmcblk0p2  /               ext4    defaults,noatime  0       1

tmpfs            /tmp           tmpfs   defaults,noatime,nosuid,size=64m    0 0
tmpfs            /var/lib/dhcp  tmpfs   defaults,noatime,nosuid,size=64m    0 0
tmpfs            /var/spool     tmpfs   defaults,noatime,nosuid,size=64m    0 0
tmpfs            /var/lock      tmpfs   defaults,noatime,nosuid,size=64m    0 0

/dev/sda2  /               ext4    defaults,noatime  0       1

EOF



./box-umount
