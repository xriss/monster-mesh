How to Build an SD card
=======================

Using Ubuntu/Debian run 00-run-all.sh which will run all the other 
numbered scripts in this directory one after the other.

	./00-run-all.sh

This will all take some time (about 30mins for me) and finally create a 
fully provisioned monster-mesh.img which can then be written to an SD 
card and booted on a Raspberry PI. Other useful scripts that can now be 
run to further manipulate this image are.

	./box-up

Will start a QEMU box. Note that you will no longer be able to use that 
shell while this box runs.
	
	./box-down

Will stop a QEMU box.

	./ssh
	
Will log you into the running QEMU box


A note on security, the user pi with password raspberry and with your 
.ssh public key setup to allow passwordless ssh login. So be sure to 
change the password and remove the .ssh key if you want the image to be 
secure.
