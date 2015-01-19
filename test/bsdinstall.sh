#!/bin/sh

cp $BSDINIT_INSTALLER_FILE /root/install.sh


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
# gpart modify -i 1 -l bootfs $MD_DEV
# gpart modify -i 2 -l rootfs $MD_DEV
# gpart show -lp $MD_DEV

sed -i '' "s/${MD_DEV}p2/vtbd0p2/" /etc/fstab

echo 'content of /etc/fstab'
cat /etc/fstab
echo '================================'
echo 'content of /etc/resolv.conf'
cat /etc/resolv.conf

# testing network
ping -c 3 8.8.8.8

sh -e $INSTALLER
