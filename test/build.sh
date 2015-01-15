#!/bin/sh

RM='rm'
MKDIR='mkdir -p'

INSTALLER_DIR=$(dirname `realpath $0`)
BSD_CLOUDINIT="${INSTALLER_DIR}/../installer.sh"

BSD_VERSION=`uname -r`
FTP_MIRROR='ftp.tw.freebsd.org'
BASE_URL="ftp://${FTP_MIRROR}/pub/FreeBSD/releases/amd64/${BSD_VERSION}/"

TEST_BASE_DIR="${INSTALLER_DIR}/base"
JAILS_CONF='/etc/jail.conf'
JAILS_NAME='tester'

echo_box() {
	echo "=============================================="
	echo "# $1"
	echo "=============================================="
}

if [ -e "$TEST_BASE_DIR" ]
then
	# service jail stop $JAILS_NAME
	jail -f $JAILS_CONF -r $JAILS_NAME
	printf "Remove older tester..."
	chflags -R noschg $TEST_BASE_DIR
	$RM -rf $TEST_BASE_DIR/*
	printf "done\n"
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

jail -f $JAILS_CONF -c $JAILS_NAME

echo_box "Start testing"
jexec $JAILS_NAME sh '/root/installer.sh' || {
	echo_box "Build failed in ${BSD_VERSION}!"
	exit 1
}
echo_box "Testing finished"
