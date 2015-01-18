#!/bin/sh

##############################################
#  variables
##############################################

# commands
RM='rm'
MKDIR='mkdir -p'

BUILDER_DIR=$(dirname `realpath $0`)
BUILDER_CONF="${BUILDER_DIR}/build.conf"
TEST_BASE_DIR="${BUILDER_DIR}/base"

# bsd cloudinit info
export INSTALLER_REV=`git rev-parse --short  HEAD`

# md
MD_UNIT=0
export MD_DEV="md${MD_UNIT}"
export MD_FILE="${BUILDER_DIR}/tester.raw"

# bsdinstall
export DISTRIBUTIONS='kernel.txz base.txz'
export BSDINSTALL_DISTSITE="ftp://ftp.tw.freebsd.org/pub/FreeBSD/releases/amd64/`uname -r`/"
export BSDINSTALL_CHROOT=$TEST_BASE_DIR
export BSDINSTALL_DISTDIR="${BUILDER_DIR}/dist"
export PARTITIONS="$MD_DEV gpt { auto freebsd-ufs / }"
BSDINSTALL_SCRIPT="${BUILDER_DIR}/bsdinstall.sh"

# virtualenv and openstack command line client
VENV_DIR="$TEST_BASE_DIR/.venv"
PIP_REQUIREMENTS="${BUILDER_DIR}/pip_requirements.txt"
PIP='pip'

. $BUILDER_CONF
. $OS_RC

##############################################
#  util functions
##############################################

echo_box() { #{{{
	echo "=============================================="
	echo "# $1"
	echo "=============================================="
} #}}}

umount_base() { #{{{
	for dir in '/dev' ''
	do
		if [ ! $TEST_BASE_DIR ]
		then
			echo 'Base dir not found.'
			exit 1
		fi
		_d=${TEST_BASE_DIR}${dir}
		if mount | cut -d' ' -f 3 | egrep "^${_d}$" > /dev/null
		then
			echo "umount ${_d}"
			umount "${_d}"
		fi
	done
} #}}}

umount_md() { #{{{
	if mdconfig -l -u $MD_UNIT > /dev/null 2>&1
	then
		printf "$MD_DEV deattach..."
		mdconfig -d -u $MD_UNIT || {
			echo 'failed'
			exit 1
		}
		echo 'done'
	fi
} #}}}

clean_base() { #{{{
	if [ -e "$TEST_BASE_DIR" ]
	then
		printf 'Remove tester base file...'
		chflags -R noschg $TEST_BASE_DIR
		$RM -rf $TEST_BASE_DIR
		echo 'done'
	fi
} #}}}

clean_venv() { #{{{
	if [ -e $VENV_DIR ]
	then
		printf 'remove virtualenv...'
		$RM -r $VENV_DIR
		echo 'done'
	fi
} #}}}

cleanup() { #{{{
	echo_box "Cleanup"
	umount_base
	umount_md
	clean_base
	clean_venv
} #}}}

attach_md() { #{{{
	# attach memory disk
	mdconfig -f $MD_FILE -u 0
	[ $? -ne 0 ] && {
		echo "Attach $MD_FILE to $MD_DEV failed"
		exit 1
	}
} #}}}



##############################################
#  main block
##############################################

trap 'cleanup' 0 1 2 15

args=`getopt t: $*`

if [ $? -ne 0 ]
then
	exit 1
fi
while [ $1 ]
do
	case $1 in
		clean )
			exit 0;
			;;
		mount )
			trap : 0
			$MKDIR $TEST_BASE_DIR
			attach_md
			bsdinstall mount
			exit 0
			;;
		umount )
			trap : 0
			umount_base
			umount_md
			exit 0
			;;
		-- )
			shift
			;;
	esac
done

cleanup

$MKDIR $TEST_BASE_DIR

attach_md

# bsdinstall script
bsdinstall checksum
if [ $? -ne 0 ] || [ ! -f $BSDINSTALL_DISTDIR/kernel.txz ] || [ ! -f $BSDINSTALL_DISTDIR/base.txz ]
then
	$MKDIR $BSDINSTALL_DISTDIR
	bsdinstall distfetch
fi

bsdinstall script $BSDINSTALL_SCRIPT || {
	cleanup
	exit 1
}

# prepare virtualenv and pip
virtualenv $VENV_DIR
. $VENV_DIR/bin/activate
$PIP install --upgrade pip
env ARCHFLAGS="-arch x86_64" LDFLAGS="-L/usr/local/lib" CFLAGS="-I/usr/local/include" $PIP install cryptography
$PIP install -r $PIP_REQUIREMENTS

# upload image

