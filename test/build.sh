#!/bin/sh

RM='rm'
MKDIR='mkdir -p'

INSTALLER_DIR=$(dirname `realpath $0`)
BSD_CLOUDINIT="${INSTALLER_DIR}/../installer.sh"

BSD_VERSION=`uname -r`
FTP_MIRROR='ftp.tw.freebsd.org'
BASE_URL="ftp://${FTP_MIRROR}/pub/FreeBSD/releases/amd64/${BSD_VERSION}/"

TEST_BASE_DIR="${INSTALLER_DIR}/base"
JAIL_CONF='/etc/jail.conf'
JAIL_NAME='tester'
JAIL="jail -f $JAIL_CONF"


##############################################
#  util functions
##############################################

echo_box() {
	echo "=============================================="
	echo "# $1"
	echo "=============================================="
}
clean_base() {
	$JAIL -r $JAIL_NAME
	printf "Remove tester base file..."
	chflags -R noschg $TEST_BASE_DIR
	$RM -rf $TEST_BASE_DIR/*
	printf "done\n"
}


##############################################
#  main block
##############################################

case $1 in
	clean )
		clean_base
		exit 0;
		;;
esac

if [ -e "$TEST_BASE_DIR" ]
then
	clean_base
fi

$MKDIR -p $TEST_BASE_DIR

(
	BASE_FILENAME='base.txz'
	cd $TEST_BASE_DIR
	echo "fetch base file: ${BASE_URL}/${BASE_FILENAME}"
	fetch ${BASE_URL}/${BASE_FILENAME}
	printf "extract base file..."
	tar Jxf $BASE_FILENAME
	$RM $BASE_FILENAME
	printf "done\n"
	echo "nameserver 8.8.8.8"> ./etc/resolv.conf
)
cp $BSD_CLOUDINIT ${TEST_BASE_DIR}/root/

$JAIL -c $JAIL_NAME

echo_box "Start installer testing"
export BSDINIT_DEBUG=yes
jexec $JAIL_NAME sh '/root/installer.sh' || {
	echo_box "Installer testing failed in ${BSD_VERSION}!"
	exit 1
}
echo_box "Installer testing finished"
