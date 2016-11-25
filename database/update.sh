#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cp $DIR/lib / -R
echo "updated DTO files"
if grep -Fxq "w1_ds2431" /etc/modules
then
	echo "w1_ds4231 already in autoload, skipping"
else
	echo "w1_ds2431" >> /etc/modules
	echo "ws_d2431 added to autoload list"
fi
echo "Installation done, please reboot now"
