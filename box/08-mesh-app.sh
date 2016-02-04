cd `dirname $0`


echo " Building the mmesh app "

cd ../mmesh
../../bin/gamecake ../mmesh/bake.lua
cd ../box

echo " Copying the mmesh app "

./scp ./adhoc-config $1
./scp ./pi-start $1

./scp ../mmesh/out/mmesh.zip $1
./scp ../../bin/exe/gamecake.raspi $1
