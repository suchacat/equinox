#!/usr/bin/env sh

if [[ "$1" == "devel" ]]; then
	sed "s|%bin|$(pwd)/equinox|g" equinox.fc.template > equinox.fc
else
	sed "s|%bin|/usr/bin/equinox|g" equinox.fc.template > equinox.fc
fi

# Compile the Equinox SELinux module
make NAME=targetted -f /usr/share/selinux/devel/Makefile

if [[ "$2" == "install" ]]; then
	sudo semodule -i equinox.pp
fi
