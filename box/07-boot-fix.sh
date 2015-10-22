cd `dirname $0`

echo " mounting boot so we can fiddle with the config "
mkdir boot
sudo mount -o umask=0000,rw,loop,offset=$((16 * 512)) monster-mesh.img ./boot
#ls ./boot

echo " setup boot config to lowres HDMI so we can plug into any monitor and see something "
sudo cat >./boot/config.txt <<EOF

gpu_mem=16

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


echo " un mounting "
sudo umount ./boot
rm -rf ./boot
