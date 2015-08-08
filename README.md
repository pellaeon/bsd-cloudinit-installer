bsd-cloudinit-installer
=======================

Installs [bsd-cloudinit](https://github.com/pellaeon/bsd-cloudinit) and transforms VM into instance template.

Warning
=======

This script will install bsd-cloudinit and configure the system, **after running this script, system settings will be changed and some data (such as SSH host key) will be destroyed, this is NOT a normal VM anymore** , you should shut down this instance and upload its disk image as an instance template.

Todo
====
1. Implement option for interacting with pkgng. Currently, we will have pkgng do all the staff automatically.
