cd `dirname $0`


# from the following sources of information

# http://blog.pi3g.com/2014/04/make-raspbian-system-read-only/
# http://blog.gegg.us/2014/03/a-raspbian-read-only-root-fs-howto/
# http://k3a.me/how-to-make-raspberrypi-truly-read-only-reliable-and-trouble-free/
# https://hallard.me/raspberry-pi-read-only/



exit

This no longer boots, probably needs to be able to write somewhere special thanks to systemd...

echo " setting the pi sd card to boot in read only mode, or at least reduce disk use "


echo " adjusting mount so root starts as readonly "


#use this fstab for card booting
./ssh " sudo tee /etc/fstab.card >/dev/null " <<EOF

proc            /proc           proc    defaults             0       0
/dev/mmcblk0p1  /boot           vfat    defaults,noatime     0       2
/dev/mmcblk0p2  /               ext4    defaults,noatime,ro  0       1

tmpfs            /tmp           tmpfs   defaults,noatime,nosuid,size=64m    0 0
tmpfs            /var/lib/dhcp  tmpfs   defaults,noatime,nosuid,size=64m    0 0
tmpfs            /var/run       tmpfs   defaults,noatime,nosuid,size=64m    0 0
tmpfs            /var/spool     tmpfs   defaults,noatime,nosuid,size=64m    0 0
tmpfs            /var/lock      tmpfs   defaults,noatime,nosuid,size=64m    0 0

#/dev/sda2      /               ext4    defaults,noatime,ro  0       1

EOF

#use this fstab for qemu booting
./ssh " sudo tee /etc/fstab.qemu >/dev/null " <<EOF

proc             /proc          proc    defaults             0       0
#/dev/mmcblk0p1  /boot          vfat    defaults,noatime     0       2
#/dev/mmcblk0p2  /              ext4    defaults,noatime,ro  0       1

tmpfs            /tmp           tmpfs   defaults,noatime,nosuid,size=64m    0 0
tmpfs            /var/lib/dhcp  tmpfs   defaults,noatime,nosuid,size=64m    0 0
tmpfs            /var/run       tmpfs   defaults,noatime,nosuid,size=64m    0 0
tmpfs            /var/spool     tmpfs   defaults,noatime,nosuid,size=64m    0 0
tmpfs            /var/lock      tmpfs   defaults,noatime,nosuid,size=64m    0 0

/dev/sda2        /              ext4    defaults,noatime,ro  0       1

EOF


echo " save time every hour "
./ssh " sudo tee /etc/cron.hourly/fake-hwclock >/dev/null " <<EOF
#!/bin/sh
#
# Simple cron script - save the current clock periodically in case of
# a power failure or other crash
 
if (command -v fake-hwclock >/dev/null 2>&1) ; then

#check if root is rw already before re mounting it
fs_mode=\$(mount | sed -n -e "s/^\/dev\/root on \/ .*(\(r[w|o]\).*/\1/p")

	if [ "$fs_mode" = "ro" ] ; then

		mount -o remount,rw /
		fake-hwclock save
		mount -o remount,ro /

	else

		fake-hwclock save

	fi

fi
EOF

echo " add ro and rw commands to remount file system and boot into ro mode"
./ssh " sudo tee /etc/bash.bashrc >/dev/null " <<EOF

alias ro='sudo mount -o remount,ro / ; fs_mode=\$(mount | sed -n -e "s/^\/dev\/root on \/ .*(\(r[w|o]\).*/\1/p")'
alias rw='sudo mount -o remount,rw / ; fs_mode=\$(mount | sed -n -e "s/^\/dev\/root on \/ .*(\(r[w|o]\).*/\1/p")'

EOF


echo " shutting down VM as we need to reboot, run box-up again to get it back"
./box-down


