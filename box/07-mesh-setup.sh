cd `dirname $0`

echo " Start doing things that are unique to monster mesh "


echo " grab the monster-mesh git repo"
./ssh " git clone https://github.com/xriss/monster-mesh "


echo " grab the gamecake engine binary repo"
./ssh " hg clone https://bitbucket.org/xixs/bin "


echo " clone, build and install olsrd2 "
./ssh " git clone git://olsr.org/oonf.git && cd oonf/build && cmake -D OONF_NO_WERROR=true .. && make && sudo make install "


