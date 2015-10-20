cd `dirname $0`

echo " running monster-mesh.img using qemu "
echo " you can no longer use this shell "

qemu-system-arm -kernel kernel-qemu -cpu arm1176 -m 256 -M versatilepb -no-reboot -append "root=/dev/sda2 panic=1 console=ttyAMA0  console=ttyS0" -hda monster-mesh.img -redir tcp:5522::22 -nographic

