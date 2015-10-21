cd `dirname $0`

THISDIR=`dirname $0`

echo " creating monster-mesh.img "


echo " copying minibian "
cp 2015-02-18-wheezy-minibian.img monster-mesh.img

echo " resizing to 2gig "
qemu-img resize monster-mesh.img 2G

echo " checking partition information "

# Get the starting offset of the root partition (not sure about trailing s)
PART_START=$(parted monster-mesh.img -ms unit s print | grep "^2" | cut -f 2 -d: | cut -f 1 -ds)

#check we have a partition size
[ "$PART_START" ] && echo " PART_START=$PART_START " || exit 20

PART_START_BYTE=$(echo "$PART_START * 512" | bc)
echo " PART_START_BYTE=$PART_START_BYTE "

echo " resizing using fdisk "
fdisk monster-mesh.img <<EOF
p
d
2
n
p
2
$PART_START

p
w
EOF
