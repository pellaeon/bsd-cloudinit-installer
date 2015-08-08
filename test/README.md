Building bsd-cloudinit images
=============================

_Note: all of these tools should be run on FreeBSD 9+._

build.sh
--------
You can use `build.sh` to build FreeBSD images with bsd-cloudinit installed.

First, create an empty disk image file, name it `tester.raw`

	truncate -s 1124M tester.raw

Then run it

	sudo ./build.sh

upload.sh
---------
You can use `upload.sh` to upload the built images to OpenStack using OpenStack API.

First, download OpenStack RC file and place it in this directory, name it as `openstackrc.sh`

Then run `upload.sh` , it will upload the image and spin up an instance from that image.

	./upload.sh
