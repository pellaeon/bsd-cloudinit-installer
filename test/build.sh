#!/bin/sh

RM='rm'
MKDIR='mkdir -p'

INSTALLER_DIR=$(dirname `realpath $0`)
BSD_CLOUDINIT="${INSTALLER_DIR}/../installer.sh"

BSD_VERSION=`uname -r`
FTP_MIRROR='ftp.tw.freebsd.org'
BASE_URL="ftp://${FTP_MIRROR}/pub/FreeBSD/releases/amd64/${BSD_VERSION}/"

TEST_BASE_DIR="/home/jails/cloudinit/"
JAILS_NAME='cloudinit'

if [ -e "$TEST_BASE_DIR" ]
then
	service jail stop $JAILS_NAME
	chflags -R noschg $TEST_BASE_DIR
	$RM -rf $TEST_BASE_DIR/*
fi
$MKDIR -p $TEST_BASE_DIR

(
	BASE_FILENAME='base.txz'
	cd $TEST_BASE_DIR
	fetch ${BASE_URL}/${BASE_FILENAME}
	tar jxf $BASE_FILENAME
	$RM $BASE_FILENAME
	# network config
	echo "nameserver 8.8.8.8"> ./etc/resolv.conf
)
cp $BSD_CLOUDINIT ${TEST_BASE_DIR}/root/

service jail start $JAILS_NAME

jexec $JAILS_NAME sh '/root/installer.sh' || {
	echo "Build failed in ${BSD_VERSION}!"
	exit 1
}
