cd `dirname $0`

echo " building monster-mesh.img from default raspbian img "

echo " copying your id_rsa.pub to the pis authorised keys for auto login "
ssh-keygen -f "$HOME/.ssh/known_hosts" -R [localhost]:5522
while ! cat ~/.ssh/id_rsa.pub | sshpass -p raspberry ssh -oStrictHostKeyChecking=no -p 5522 pi@localhost " mkdir -p .ssh ; cat >> .ssh/authorized_keys "
do
	sleep 1
    echo "Trying ssh login again..."
done

echo " apply final resize of partition "
./ssh " sudo resize2fs /dev/sda2 "

echo " updating apt info and sites"
./ssh " sudo apt-get -y update "
./ssh " sudo apt-get -y upgrade "

#echo " getting latest firmware"
#echo " if we are currently broken this may fix stuff, but if we are currently fixed this may break stuff "
#echo " so this is either a good idea, or a bad idea, comment it out if it was a bad idea "
#./ssh " sudo rpi-update "

echo " installing lots of packages we will need later "
./ssh " sudo apt-get -y install aptitude sudo nano byobu git gcc build-essential cmake pkg-config libnl-genl-3-dev wireless-tools firmware-ralink kbd raspi-config lynx curl traceroute dbus consolekit input-utils wavemon dstat mercurial libnss-mdns"

echo " remove some things that we really don't want to write to the sd card all the time "
./ssh " sudo apt-get -y remove --purge triggerhappy logrotate dbus dphys-swapfile "
./ssh " sudo apt-get -y autoremove --purge "

echo " replace log system "
./ssh " sudo apt-get -y install busybox-syslogd; sudo dpkg --purge rsyslog "

echo " installing dev tools needed for later building "
./ssh " sudo apt-get -y install git gcc build-essential cmake pkg-config libnl-genl-3-dev "



