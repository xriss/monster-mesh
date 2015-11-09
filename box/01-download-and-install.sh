cd `dirname $0`



if [ -f 2015-09-24-raspbian-jessie.img ] ; then

	echo " 2015-09-24-raspbian-jessie.img exists so skipping download and unpack"

else

	wget https://downloads.raspberrypi.org/raspbian/images/raspbian-2015-09-28/2015-09-24-raspbian-jessie.zip
	unzip 2015-09-24-raspbian-jessie.zip
	rm 2015-09-24-raspbian-jessie.zip

fi


#if [ -f 2015-02-18-wheezy-minibian.img ] ; then
#	echo " 2015-02-18-wheezy-minibian.img exists so skipping download and unpack"
#else
#	wget -O minibian.img.tar.gz http://sourceforge.net/projects/minibian/files/2015-02-18-wheezy-minibian.tar.gz/download
#	tar xvfz minibian.img.tar.gz
#	rm minibian.img.tar.gz
#fi

if [ -f kernel-qemu ] ; then

	echo " kernel-qemu exists so skipping download "

else

	wget -O kernel-qemu https://github.com/polaco1782/raspberry-qemu/blob/master/kernel-qemu?raw=true

fi

