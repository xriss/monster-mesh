cd `dirname $0`


# from the following sources of information

# http://blog.pi3g.com/2014/04/make-raspbian-system-read-only/
# http://blog.gegg.us/2014/03/a-raspbian-read-only-root-fs-howto/
# http://k3a.me/how-to-make-raspberrypi-truly-read-only-reliable-and-trouble-free/
# https://hallard.me/raspberry-pi-read-only/


echo " setting the pi sd card to boot in read only mode "



echo " remove some things that we really do want to get in our way "
./ssh " apt-get -y remove --purge triggerhappy logrotate dbus dphys-swapfile "
./ssh " apt-get -y autoremove --purge "


echo " replace log system "
./ssh " apt-get -y install busybox-syslogd; dpkg --purge rsyslog "


echo " mount ro on boot "
./ssh " cat >/etc/fstab " <<EOF

/dev/mmcblk0p1 /boot vfat defaults,ro         0 2
/dev/mmcblk0p2 /     ext4 defaults,noatime,ro 0 1

#under qemu the above fails but the following replaces it

/dev/sda1 /boot vfat defaults,ro         0 2
/dev/sda2 /     ext4 defaults,noatime,ro 0 1

EOF

echo " save time every hour "
./ssh " cat >/etc/cron.hourly/fake-hwclock " <<EOF
#!/bin/sh
#
# Simple cron script - save the current clock periodically in case of
# a power failure or other crash
 
if (command -v fake-hwclock >/dev/null 2>&1) ; then
  mount -o remount,rw /
  fake-hwclock save
  mount -o remount,ro /
fi
EOF

echo " add ro and rw commands to remount file system"
./ssh " cat >>/etc/bash.bashrc " <<EOF

alias ro='mount -o remount,ro / ; fs_mode=$(mount | sed -n -e "s/^\/dev\/root on \/ .*(\(r[w|o]\).*/\1/p")'
alias rw='mount -o remount,rw / ; fs_mode=$(mount | sed -n -e "s/^\/dev\/root on \/ .*(\(r[w|o]\).*/\1/p")'

EOF

echo " delete dirs full of tmp files and relink them into /tmp (ram) then reboot "
./ssh " rm -rf /var/lib/dhcp/ && ln -s /tmp /var/lib/dhcp ; rm -rf /var/run /var/spool /var/lock && ln -s /tmp /var/run && ln -s /tmp /var/spool && ln -s /tmp /var/lock ; reboot "
