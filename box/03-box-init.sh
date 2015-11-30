cd `dirname $0`

THISDIR=`dirname $0`

echo " creating monster-mesh.img "


echo " copying diet raspbian "
#cp 2015-09-24-raspbian-jessie.img monster-mesh.img
cp diet-raspbian-2.0.0.img monster-mesh.img



echo " resizing to 3gig "
qemu-img resize monster-mesh.img 3G

echo " checking partition information "

PART_BOOT_START=$(parted monster-mesh.img -ms unit s print | grep "^1" | cut -f 2 -d: | cut -f 1 -ds)
PART_ROOT_START=$(parted monster-mesh.img -ms unit s print | grep "^2" | cut -f 2 -d: | cut -f 1 -ds)
echo $PART_BOOT_START $PART_ROOT_START

echo " resizing using fdisk "
fdisk monster-mesh.img <<EOF
p
d
2
n
p
2
$PART_ROOT_START

p
w
EOF


./box-mount

echo " setup boot config to lowres HDMI so we can plug into any monitor and see something "
sudo tee boot/config.txt >/dev/null <<EOF

gpu_mem=32

hdmi_force_hotplug=1
hdmi_drive=2
hdmi_group=1
config_hdmi_boost=4

#uncomment below to force 640x480
#hdmi_mode=1

EOF
#cat ./boot/config.txt


#use these for card booting
sudo tee root/etc/fstab.card >/dev/null <<EOF

proc            /proc           proc    defaults          0       0
/dev/mmcblk0p1  /boot           vfat    defaults,noatime  0       2
/dev/mmcblk0p2  /               ext4    defaults,noatime  0       1

tmpfs            /tmp           tmpfs   defaults,noatime,nosuid,size=64m    0 0
tmpfs            /var/lib/dhcp  tmpfs   defaults,noatime,nosuid,size=64m    0 0
tmpfs            /var/run       tmpfs   defaults,noatime,nosuid,size=64m    0 0
tmpfs            /var/spool     tmpfs   defaults,noatime,nosuid,size=64m    0 0
tmpfs            /var/lock      tmpfs   defaults,noatime,nosuid,size=64m    0 0

#/dev/sda2  /               ext4    defaults,noatime  0       1

EOF
sudo tee root/etc/ld.so.preload.card >/dev/null <<EOF

/usr/lib/arm-linux-gnueabihf/libarmmem.so

EOF


#use these for qemu booting
sudo tee root/etc/fstab.qemu >/dev/null <<EOF

proc             /proc           proc    defaults          0       0
#/dev/mmcblk0p1  /boot           vfat    defaults,noatime  0       2
#/dev/mmcblk0p2  /               ext4    defaults,noatime  0       1

tmpfs            /tmp           tmpfs   defaults,noatime,nosuid,size=64m    0 0
tmpfs            /var/lib/dhcp  tmpfs   defaults,noatime,nosuid,size=64m    0 0
tmpfs            /var/run       tmpfs   defaults,noatime,nosuid,size=64m    0 0
tmpfs            /var/spool     tmpfs   defaults,noatime,nosuid,size=64m    0 0
tmpfs            /var/lock      tmpfs   defaults,noatime,nosuid,size=64m    0 0

/dev/sda2  /               ext4    defaults,noatime  0       1

EOF
sudo tee root/etc/ld.so.preload.qemu >/dev/null <<EOF

#/usr/lib/arm-linux-gnueabihf/libarmmem.so

EOF



./box-umount
