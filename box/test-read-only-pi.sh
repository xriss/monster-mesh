cd `dirname $0`


# from the following sources of information

# http://blog.pi3g.com/2014/04/make-raspbian-system-read-only/
# http://blog.gegg.us/2014/03/a-raspbian-read-only-root-fs-howto/
# http://k3a.me/how-to-make-raspberrypi-truly-read-only-reliable-and-trouble-free/
# https://hallard.me/raspberry-pi-read-only/


echo " setting the pi sd card to boot in read only mode "


echo " remove some things that we really dont want to get in our way "
./ssh " sudo apt-get -y remove --purge triggerhappy logrotate dbus dphys-swapfile "
./ssh " sudo apt-get -y autoremove --purge "


echo " replace log system "
./ssh " sudo apt-get -y install busybox-syslogd; sudo dpkg --purge rsyslog "


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

./ssh " sudo tee /etc/rc.local >/dev/null " <<EOF

echo "Switching root to ReadOnly mode"
sudo mount -o remount,ro /

exit 0

EOF

echo " delete dirs full of tmp files and relink them into /tmp (ram) then reboot "
./ssh " sudo rm -rf /var/lib/dhcp/ && sudo ln -s /tmp /var/lib/dhcp ; sudo rm -rf /var/run /var/spool /var/lock && sudo ln -s /tmp /var/run && sudo ln -s /tmp /var/spool && sudo ln -s /tmp /var/lock "

echo " shutting down VM as we need to reboot, run box-up again to get it back"
./box-down
