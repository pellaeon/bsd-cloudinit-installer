#!/bin/sh

SSH_DIR=/etc/ssh
RC_TMP_FILE="/tmp/installer.rc.tmp.$$"
BSDINIT_URL="https://github.com/pellaeon/bsd-cloudinit/archive/master.tar.gz"


[ ! `where python2.7` ] && { 
	echo 'python2.7 Not Found !' 
	exit 1
	}
PYTHON=`where python2.7`

fetch -o - BSDINIT_URL | tar -xzvf - -C '/root'

rm -vf $SSH_DIR/ssh_host*

touch $RC_TMP_FILE
RC_STARTLINE=`cat -n /etc/rc | awk '/rc.subr/ { print $1 }'`
RC_ENDLINE=`cat -n /etc/rc | tail -n 1 | awk '{ print $1 }'`
RC_BACKUP_FILE='/etc/rc.orig'
cp -pvf /etc/rc $RC_BACKUP_FILE
head -n $RC_STARTLINE /etc/rc > $RC_TMP_FILE
echo "(cd /root/bsd-cloudinit-master/ && $PYTHON ./cloudinit && mv $RC_BACKUP_FILE /etc/rc )" >> $RC_TMP_FILE
tail -n `expr $RC_ENDLINE -  $RC_STARTLINE` /etc/rc >> $RC_TMP_FILE
cp -pvf $RC_TMP_FILE /etc/rc
