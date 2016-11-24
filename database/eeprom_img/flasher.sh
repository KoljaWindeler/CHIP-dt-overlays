#!/bin/bash
list_file()
{
	NR=1
	for f in $DIR"/*.img"; do :
		echo "Reading $f.."
		decode $f
		if [ "$MAGIC" -eq "CHIP" ]; then :
			echo "($NR) $VENDOR_NAME: $PRODUCT_NAME (v$PRODUCT_V)"
		else
			echo "Not yet programmed with a CHIP DIP EEPROM image"
		fi
		NR=$((NR+1))
	done
}

list_sys()
{
	for e in "/sys/bus/w1/devices/*/eeprom"
	do
		echo "Reading connected EEPROM $e.."
		decode $e
		if [ "$MAGIC" -eq "CHIP" ]; then :
			echo "($NR) $VENDOR_NAME: $PRODUCT_NAME (v$PRODUCT_V)"
			NR=$((NR+1))
		else
			echo "Not a CHIP DIP EEPROM image"
		fi
	done
}

decode()
{
	MAGIC=`head -c 4 $f | hexdump`
	VENDOR_ID=`head -c 9 $1 | tail -c 4 | hexdump`
	PRODUCT_ID=`head -c 11 $1 | tail -c 2 | hexdump`
	PRODUCT_V=`head -c 13 $1 | tail -c 1 | hexdump`
	VENDOR_NAME=`head -c 45 $1 | tail -c 32 | hexdump`
	PRODUCT_NAME=`head -c 67 $1 | tail -c 32 | hexdump`
}

######## start here ########
if [ "$EUID" -ne 0 ]; then :
	echo "Please run as root"
	exit
fi
# prepare empty strings
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
MAGIC=
VENDOR_ID=
PRODUCT_ID=
PRODUCT_V=
VENDOR_NAME=
PRODUCT_NAME=
NR=1
IMG_NAME=
IMG_FILE=
EEPROM_FILE=
modprobe w1_ds2431

echo "Welcome to the CHIP EEPROM flasher tool"
echo "List of all connected ICs:"
list_sys
if [ $NR -gt 2 ]; then : # at least 2 found 
	echo -n "Which IC do you want to program > "
	read EEPROM_NR
else 
	EEPROM_NR=1
fi

echo "List of all available images"
list_file
if [ $NR -gt 2 ]; then : # at least 2 found 
	echo -n "Which image do you want to flash > "
	read IMG_NR
else 
	IMG_NR=1
fi

confirm=""
##### get image file for selected nr
NR=1
for f in $DIR"/*.img"; do :
	if [ "$NR" -eq "$IMG_NR"]; then :
		IMG_FILE=$f
		decode $f
		IMG_NAME=$PRODUCT_NAME
	fi
	NR=$((NR+1))
done
##### get eeprom for selected nr
NR=1
for f in "/sys/bus/w1/devices/*/eeprom"; do :
	if [ "$NR" -eq "$EEPROM_NR"]; then :
		EEPROM_FILE=$f
	fi
	NR=$((NR+1))
done

##### confirm 
while [ "$confirm" -ne "y" -a "$confirm" -ne "n" ]; do :
	echo -n "Please confirm to flash image $IMG_NAME to $EEPROM_FILE (y/n) > "
	read confirm
done

##### flash
if [ "$confirm" -eq "y" ]; then :
	echo -n "Flashing "
	cat $IMG_FILE > $EEPROM_FILE; ST=$?
	if [ $ST -ne 0 ]; then :
	  echo "Flashing failed"
	 else
		echo "done"
	fi
fi