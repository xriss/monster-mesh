How to Build an SD card
=======================

Using Ubuntu/Debian run **ALL** the numbered scripts in this directory one 
after the other.

eg

	./01-download-and-install.sh
	
then

	./02-install.sh

and so on

	./03-initalize-box.sh
	./04-run-box.sh

at this point the shell will be taken over by a running QEMU box and 
you will have to continue running the rest of the scripts in another 
shell.

	./05-setup-box.sh
	./06-read-only-pi.sh

This will all take some time (hours?) and finally create a fully 
provisioned monster-mesh.img which can then be written to an SD card 
and booted on a Raspberry PI. Other useful scripts that can now be run 
are.

	./box-up

Will start a QEMU box. Note that you will no longer be able to use that 
shell while this box runs.
	
	./box-down

Will stop a QEMU box.

	./ssh
	
Will log you into a running QEMU box
