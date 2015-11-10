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

./box-umount
