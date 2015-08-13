#!/bin/sh

##############################################
#  variables
##############################################

# commands
RM='rm'
MKDIR='mkdir -p'

. "tester.conf"


# instance
VM_BOOT_SLEEP_TIME=120

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

cleanup() { #{{{
	echo_box "Cleanup"
	umount_base
	umount_md
	clean_base
} #}}}

attach_md() { #{{{
	# attach memory disk
	mdconfig -f $MD_FILE -u $MD_UNIT
	[ $? -ne 0 ] && {
		echo "Attach $MD_FILE to $MD_DEV failed"
		exit 1
	}
	mdconfig -l -u $MD_UNIT
} #}}}

usage() { #{{{
	echo "Usage $0: [options] [command]"
	printf "\toptions:\n"
	for i in "-d -- build debug image"
	do
		printf "\t\t$i\n"
	done
	printf "\tcommands:\n"
	for i in "clean" "mount" "umount" "chroot" "upload [image file]"\
		"boot [vm name]" "install"
	do
		printf "\t\t$i\n"
	done
} #}}}

install_os() { #{{{
	bsdinstall checksum
	if [ $? -ne 0 ] || [ ! -f $BSDINSTALL_DISTDIR/kernel.txz ] || [ ! -f $BSDINSTALL_DISTDIR/base.txz ]
	then
		$MKDIR $BSDINSTALL_DISTDIR
		bsdinstall distfetch
	fi
	bsdinstall scriptedpart $PARTITIONS
	bsdinstall script $BSDINSTALL_SCRIPT || {
		cleanup
		exit 1
	}
} #}}}

post_install_os(){ #{{{
	if [ $BSDINIT_DEBUG ]
	then
		echo_box 'start post installation'
		bsdinstall mount
		sh ${BUILDER_DIR}/post_install.sh
		$0 umount
		echo_box 'post installation end'
	fi
} #}}}

##############################################
#  main block
##############################################

trap 'cleanup' 0 1 2 15

args=`getopt dr: $*`

if [ $? -ne 0 ]
then
	exit 1
fi
while [ $1 ]
do
	case $1 in
		-d )
			export BSDINIT_DEBUG=yes
			echo "Build debug image."
			shift
			;;
		-r )
			shift
			export GIT_REF=$1
			echo "Build ref:${GIT_REF}"
			shift
			;;
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
		chroot )
			trap : 0
			chroot $BSDINSTALL_CHROOT tcsh
			exit 0
			;;
		upload )
			trap : 0
			upload_img $2
			exit 0
			;;
		boot )
			trap : 0
			boot_img $2
			exit 0
			;;
		install )
			trap : 0
			umount_base
			umount_md
			attach_md
			install_os
			exit 0
			;;
		postinstall)
			trap : 0
			umount_base
			umount_md
			attach_md
			post_install_os
			exit 0
			;;
		test_instance)
			trap : 0
			test_instance
			exit 0
			;;
		-- )
			shift
			;;
		* )
			trap : 0 1 2 15
			usage
			exit 1
			;;
	esac
done

cleanup

$MKDIR $TEST_BASE_DIR

attach_md

install_os

post_install_os

umount_base
umount_md
