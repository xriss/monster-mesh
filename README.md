How to Monster Mesh
===================


Install and start **MINIBIAN**, a minimal Raspbian-based Linux image for Raspberry Pi.

http://sourceforge.net/projects/minibian/ (*512mb partition*)

Login ```root```

Password ```raspberry```


Install and run **raspi-config** to resize the partition and then reboot.

```
apt-get install raspi-config
raspi-config
reboot
```

Install **Byobu**.

```
apt-get install aptitude sudo nano byobu
```

Now we can use **nano**

```
nano /boot/config.txt
```

Set the following in **/boot/config.txt** to force 640x480 hdmi output always.

```
hdmi_force_hotplug=1
hdmi_drive=2
hdmi_group=1
hdmi_mode=1
config_hdmi_boost=4
```

To turn off screen blanking, make sure **kbd** is installed.

```
aptitude install kbd
```

Edit the following config to set BLANK_TIME=0

```
nano /etc/kbd/config
```

Reboot for the above to take effect.

```
reboot
```

Now we need a build environment for **olsrd2** to be built from source.

```
sudo aptitude install git gcc build-essential cmake
```

Since this version of **cmake** is too old for **olsrd2**, we will need to build a newer one.

```
git clone git://cmake.org/cmake.git
cd cmake
cmake .
make
make install
reboot
```


More dependencies needed to build **olsrd2**.

```
aptitude install pkg-config libnl-genl-3-dev
```

We are still in **/root** so grab the **olsrd2** and build it.

```
git clone git://olsr.org/oonf.git
cd oonf/build
```

Ignore any warnings as there may be some.

```
cmake -D OONF_NO_WERROR=true ..
make
make install
```

Make sure we have WLAN drivers.

```
aptitude install wireless-tools firmware-ralink
```

Add the following setup to **/etc/network/interface**.

```
auto wlan1
iface wlan1 inet static
  wireless-essid monster-mesh
  wireless-mode Ad-Hoc
  wireless-channel 1
  address 192.168.0.0
  netmask 255.255.0.0
```

Now push it up.

```
ifup wlan1
```


Finally, run the command below to (*hopefully*) start the mesh!

```
olsrd2_static --set log.debug=auto_ll4 --set global.plugin=auto_ll4 wlan1
```


