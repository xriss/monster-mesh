cd `dirname $0`

echo " building monster-mesh.img from default *mini* raspbian img "


cat ~/.ssh/id_rsa.pub | sshpass -p raspberry ssh -p 5522 root@localhost " mkdir -p .ssh ; cat >> .ssh/authorized_keys "

echo " apply final resize of partition "
./ssh " resize2fs /dev/sda2 "

echo " updating apt info and sites "
./ssh " apt-get -y update "
./ssh " apt-get -y upgrade "

echo " installing lots of packages we will need later "
./ssh " apt-get -y install aptitude sudo nano byobu git gcc build-essential cmake pkg-config libnl-genl-3-dev wireless-tools firmware-ralink kbd "


echo " setup boot config to lowres HDMI so we can plug into any monitor and see something "
./ssh " cat > /boot/config.txt " <<EOF

gpu_mem=16

hdmi_force_hotplug=1
hdmi_drive=2
hdmi_group=1
hdmi_mode=1
config_hdmi_boost=4

EOF

echo " disable swap and filesystem check on boot (ignore clock skew hang) "
./ssh " cat >/boot/cmdline.txt " <<EOF

fastboot noswap

EOF


echo " setting up KBD to disable screen blank "
./ssh " sed -i -e 's/getty 38400 tty1/getty --noclear 38400 tty1/g' /etc/inittab "

echo " preparing to build "
./ssh " apt-get -y install git gcc build-essential cmake pkg-config libnl-genl-3-dev "

echo " clone build install a newer version of cmake as the repo is out of date"
./ssh " git clone git://cmake.org/cmake.git && cd cmake && cmake . && make && make install "

echo " clone build install olsrd2 "
./ssh " git clone git://olsr.org/oonf.git && cd oonf/build && cmake -D OONF_NO_WERROR=true .. && make && make install "

