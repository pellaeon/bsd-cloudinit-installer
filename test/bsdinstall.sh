
#!/bin/sh

FETCH='fetch --no-verify-peer'
INSTALLER='/root/install.sh'

##############################################
#  utils
##############################################

cleanup(){ #{{{
	rm -v /etc/resolv.conf
	exit
} #}}}


##############################################
#  main block
##############################################

trap 'cleanup' 0 1 2 15

set -e

echo 'nameserver 8.8.8.8' > /etc/resolv.conf

# Add gpt label
gpart modify -i 2 -l rootfs $MD_DEV
sed -i '' "s/${MD_DEV}p2/gpt\/rootfs/" /etc/fstab

echo '/etc/fstab'
cat /etc/fstab
echo '================================'
echo '/etc/resolv.conf'
cat /etc/resolv.conf

# testing network
ping -c 5 8.8.8.8

# install bsd cloudinit

if [ ! $BSDINIT_INSTALLER_URL ]
then
	echo 'Installer url not found.'
	exit 1
fi

$FETCH -o $INSTALLER $BSDINIT_INSTALLER_URL
sh -e $INSTALLER
