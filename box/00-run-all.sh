cd `dirname $0`

./01-download.sh
./02-install.sh
./03-box-init.sh
./04-box-softboil.sh
./05-box-up.sh

#need to wait for box to be ready for login here

./06-box-setup.sh
./07-mesh-setup.sh
./08-box-down.sh


