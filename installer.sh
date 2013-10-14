#!/bin/sh

SSH_DIR=/etc/ssh
RC_TMP_FILE="/tmp/installer.rc.tmp.$$"
RC_SCRIPT_FILE='/etc/rc'
RC_BACKUP_FILE='/etc/rc.orig'
RC_STARTLINE=`cat -n $RC_SCRIPT_FILE | awk '/rc.subr/ { print $1 }'`
RC_ENDLINE=`cat -n $RC_SCRIPT_FILE | tail -n 1 | awk '{ print $1 }'`
BSDINIT_URL="https://github.com/pellaeon/bsd-cloudinit/archive/master.tar.gz"


[ ! `which python2.7` ] && {
	echo 'python2.7 Not Found !' 
	exit 1
	}
PYTHON=`which python2.7`

fetch -o - $BSDINIT_URL | tar -xzvf - -C '/root'

rm -vf $SSH_DIR/ssh_host*

touch $RC_TMP_FILE
cp -pvf $RC_SCRIPT_FILE $RC_BACKUP_FILE
head -n $RC_STARTLINE $RC_SCRIPT_FILE > $RC_TMP_FILE
echo "(cd /root/bsd-cloudinit-master/ && $PYTHON ./cloudinit && cp -pvf $RC_BACKUP_FILE $RC_SCRIPT_FILE )" >> $RC_TMP_FILE
tail -n `expr $RC_ENDLINE -  $RC_STARTLINE` $RC_SCRIPT_FILE >> $RC_TMP_FILE
cp -pvf $RC_TMP_FILE $RC_SCRIPT_FILE
