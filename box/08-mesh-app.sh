cd `dirname $0`


echo " Building the mmesh app "

../../bin/gamecake ../mmesh/build.lua

echo " Copying the mmesh app "

scp -P 5522 ./adhoc-config pi@localhost:
scp -P 5522 ./pi-start pi@localhost:

scp -P 5522 ../mmesh/out/mmesh.zip pi@localhost:
scp -P 5522 ../../bin/exe/gamecake.raspi pi@localhost:
