cd `dirname $0`

echo "starting qemu but detaching it from this shell, wait until a login prompt apears before running the next script"
./box-up &
