
#!/bin/sh

FETCH='fetch --no-verify-peer'
INSTALLER='/root/install.sh'

echo 'nameserver 8.8.8.8' > /etc/resolv.conf

if [ ! $BSDINIT_INSTALLER_URL ]
then
	echo 'Installer url not found.'
	exit 1
fi

$FETCH -o $INSTALLER $BSDINIT_INSTALLER_URL
sh $INSTALLER
