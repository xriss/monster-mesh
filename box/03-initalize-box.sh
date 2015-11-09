cd `dirname $0`

THISDIR=`dirname $0`

echo " creating monster-mesh.img "


echo " copying raspbian "
#cp 2015-09-24-raspbian-jessie.img monster-mesh.img

./box-mount

echo " setup boot config to lowres HDMI so we can plug into any monitor and see something "
sudo cat >./boot/config.txt <<EOF

gpu_mem=32

hdmi_force_hotplug=1
hdmi_drive=2
hdmi_group=1
hdmi_mode=1
config_hdmi_boost=4

EOF
#cat ./boot/config.txt


echo " disable swap and filesystem check on boot (ignore clock skew hang) "
sudo cat >./boot/cmdline.txt <<EOF

dwc_otg.lpm_enable=0 console=ttyAMA0,115200 kgdboc=ttyAMA0,115200 console=tty1 elevator=deadline root=/dev/mmcblk0p2 rootfstype=ext4 rootwait fastboot noswap

EOF
#cat ./boot/cmdline.txt

./box-umount
