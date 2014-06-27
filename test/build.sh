#!/bin/sh

RM='rm'
MKDIR='mkdir -p'

BSD_CLOUDINIT='../installer.sh'

BSD_VERSION='10.0'
FTP_MIRROR='ftp.tw.freebsd.org'
BASE_URL="ftp://${FTP_MIRROR}/pub/FreeBSD/releases/amd64/${BSD_VERSION}-RELEASE/"

TEST_BASE_DIR="base_${BSD_VERSION}"

if [ -e "$TEST_BASE_DIR" ]
then
	chflags -R noschg $TEST_BASE_DIR
	$RM -rf $TEST_BASE_DIR
fi
$MKDIR $TEST_BASE_DIR

(
	BASE_FILENAME='base.txz'
	cd $TEST_BASE_DIR
	fetch ${BASE_URL}/${BASE_FILENAME}
	tar jxf $BASE_FILENAME
	$RM $BASE_FILENAME
	# copy network config
	cp /etc/resolv.conf ./etc/
	# prepare fake uname
	UNAME_PATH='./usr/bin/uname'
	rm $UNAME_PATH
	echo "#!/bin/sh
	echo ${BSD_VERSION}-RELEASE
	" > $UNAME_PATH
	chmod +x $UNAME_PATH
)
cp $BSD_CLOUDINIT ${TEST_BASE_DIR}/root/

CH_PATH='/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin'
CHROOT_EXEC="env -i SHELL=/bin/sh PATH=${CH_PATH} chroot $TEST_BASE_DIR"

$CHROOT_EXEC '/root/installer.sh' || {
	echo "Build failed in ${BSD_VERSION}-RELEASE!"
	exit 1
}
