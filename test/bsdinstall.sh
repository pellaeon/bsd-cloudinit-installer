#!/bin/sh
# This file is used as bsdinstall(8) script, see the SCRIPTING section in bsdinstall(8) for more details

# This variable is used to carry content from host to the chroot'ed system
# Instead of downloading bsd-cloudinit-installer directly in the chroot,
# this approach allows you to modify bsd-cloudinit-installer/installer.sh
# and test it using this script.
export FLS_INSTALLER_CONTENT="`/usr/bin/openssl enc -base64 < $BSDINIT_INSTALLER_FILE`"

if [ $GIT_REF ]
then
	INSTALLER_FLAGS="-r $GIT_REF"
fi


#!/bin/sh

INSTALLER_PATH='/root/installer.sh'

##############################################
#  utils
##############################################

cleanup(){ #{{{
	rm -v /etc/resolv.conf
	rm -v $INSTALLER
	exit
} #}}}


##############################################
#  main block
##############################################

trap 'cleanup' 0 1 2 15

set -e

echo "$FLS_INSTALLER_CONTENT" | /usr/bin/openssl enc -base64 -d > $INSTALLER_PATH

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

# installer.sh needs Internet access
ping -c 3 8.8.8.8

sh -e $INSTALLER_PATH $INSTALLER_FLAGS
