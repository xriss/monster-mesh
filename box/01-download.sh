cd `dirname $0`

#http://director.downloads.raspberrypi.org/raspbian/images/raspbian_lite-2016-02-09/2016-02-09-raspbian-jessie-lite.zip
#http://director.downloads.raspberrypi.org/raspbian/images/raspbian_lite-2015-11-24/2015-11-21-raspbian-jessie-lite.zip

#update these to get a newer version
RASPBIAN_FILE=2016-02-09-raspbian-jessie-lite
RASPBIAN_URL=https://downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-2016-02-09/$RASPBIAN_FILE.zip


if [ -f raspbian.img ] ; then

	echo " raspbian.img exists so skipping download and unpack "

else

	wget -O $RASPBIAN_FILE.zip $RASPBIAN_URL
	unzip -o $RASPBIAN_FILE.zip
	rm $RASPBIAN_FILE.zip
	mv $RASPBIAN_FILE.img raspbian.img

fi




if [ -f kernel-qemu ] ; then

	echo " kernel-qemu exists so skipping download "

else

	wget -O kernel-qemu https://github.com/polaco1782/raspberry-qemu/blob/master/kernel-qemu?raw=true

fi

