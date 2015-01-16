#!/bin/sh

RM='rm'
MKDIR='mkdir -p'

BUILDER_DIR=$(dirname `realpath $0`)
BUILDER_CONF="${BUILDER_DIR}/build.conf"

. $BUILDER_CONF

BSD_CLOUDINIT="${BUILDER_DIR}/../installer.sh"

BSD_VERSION=`uname -r`
FTP_MIRROR='ftp.tw.freebsd.org'
BASE_URL="ftp://${FTP_MIRROR}/pub/FreeBSD/releases/amd64/${BSD_VERSION}/"

TEST_BASE_DIR="${BUILDER_DIR}/base"
JAIL_CONF='/etc/jail.conf'
JAIL_NAME='tester'
JAIL="jail -f $JAIL_CONF"
MD_UNIT=0
MD_DEV="md$MD_UNIT"
MD_FILE="${BUILDER_DIR}/tester.raw"
BSDINSTALL_SCRIPT="${BUILDER_DIR}/bsdinstall.sh"


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
	printf 'Remove tester base file...'
	chflags -R noschg $TEST_BASE_DIR
	$RM -rf $TEST_BASE_DIR/*
	if mdconfig -l -u $MD_UNIT > /dev/null 2>&1
	then
		mdconfig -d -u $MD_UNIT
		echo "$MD_DEV removed..."
	fi
	printf 'done\n'
}


##############################################
#  main block
##############################################

args=`getopt t: $*`

if [ $? -ne 0 ]
then
	exit 1
fi
while [ $1 ]
do
	case $1 in
		-t )
			JAIL_NAME=$2
			shift; shift;
			;;
		clean )
			clean_base
			exit 0;
			;;
		-- )
			shift
			;;
	esac
done

if [ -e "$TEST_BASE_DIR" ]
then
	clean_base
fi

$MKDIR $TEST_BASE_DIR

# prepare md
mdconfig -f $MD_FILE -u 0
[ $? -ne 0 ] && {
	echo "Create $MD_DEV failed"
	exit 1
}

# bsdinstall script
export DISTRIBUTIONS='kernel.txz base.txz'
export BSDINSTALL_DISTSITE=$BASE_URL
export BSDINSTALL_CHROOT=$TEST_BASE_DIR
export BSDINSTALL_DISTDIR="${BUILDER_DIR}/dist"
export PARTITIONS=$MD_DEV

bsdinstall checksum
if [ $? -ne 0 ] || [ ! -f $BSDINSTALL_DISTDIR/kernel.txz ] || [ ! -f $BSDINSTALL_DISTDIR/base.txz ]
then
	$MKDIR $BSDINSTALL_DISTDIR
	bsdinstall distfetch
fi

bsdinstall scriptedpart $MD_DEV { auto freebsd-ufs / }
bsdinstall script $BSDINSTALL_SCRIPT
