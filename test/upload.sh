#/bin/sh

BUILDER_DIR=$(dirname `realpath $0`)
BUILDER_CONF="${BUILDER_DIR}/upload.conf"
TEST_BASE_DIR="${BUILDER_DIR}/base"

# virtualenv and openstack command line client
VENV_DIR="$BUILDER_DIR/.venv"
PIP_REQUIREMENTS="${BUILDER_DIR}/pip_requirements.txt"
PIP='pip'

. $BUILDER_CONF
. $OS_RC

clean_venv() { #{{{
	if [ -e $VENV_DIR ]
	then
		printf 'remove virtualenv...'
		$RM -r $VENV_DIR
		echo 'done'
	fi
} #}}}

upload_img() { #{{{
	python2 $BUILDER_DIR/tools/image.py $1
} #}}}

boot_img() { #{{{
	python2 $BUILDER_DIR/tools/compute.py $1
} #}}}

test_instance(){ #{{{
	fab main
} #}}}

# prepare virtualenv and pip for access openstack command line clients
virtualenv $VENV_DIR
. $VENV_DIR/bin/activate
$PIP install --upgrade pip
env ARCHFLAGS="-arch x86_64" LDFLAGS="-L/usr/local/lib" CFLAGS="-I/usr/local/include" $PIP install cryptography
$PIP install -r $PIP_REQUIREMENTS

upload_img

boot_img

# echo "Sleep $VM_BOOT_SLEEP_TIME for nova finishing booting ..."
# sleep $VM_BOOT_SLEEP_TIME

# test_instance
