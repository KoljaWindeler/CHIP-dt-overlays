#!/bin/bash
# call e.g.  flasher.sh -e 1 -i 2 -y -r

list_file()
{
	NR=1
	f=""
	for f in $DIR/*.img; do :
		f_SHORT=`echo $f|rev|cut -d "/" -f1|rev`
		f_SHORT=`echo $f_SHORT"           "|head -c 30`
		echo -n -e "($NR) $f_SHORT: "
		decode $f
		if [ "$MAGIC" = "CHIP" ]; then :
			echo "$VENDOR_NAME, $PRODUCT_NAME (v$PRODUCT_V)"
		else
			echo "Not yet programmed with a CHIP DIP EEPROM image"
		fi
		NR=$((NR+1))
	done
	MAX_FILE=$((NR-1))
}

list_sys()
{
	rm /tmp/eeprom >/dev/null 2>&1
	NR=1
	for e in /sys/bus/w1/devices/*/eeprom; do :
		e_SHORT=`echo $e|rev|cut -d "/" -f2|rev`
		TRY=0
		ST=1
		# avoid multiple readings
		while [ $ST -ne 0 -a $TRY -lt 10 ]; do :
			dd if=$e of=/tmp/eeprom status=none
			ST=$?
			TRY=$((TRY+1))
			if [ $ST -ne 0 ]; then
				echo ""
				echo "ERROR: Reading EEPROM failed, retry $TRY"
			elif [ $TRY -gt 1 ]; then
				echo "Reading EEPROM done"
			fi
		done

		echo -n "($NR) $e_SHORT: "	
		decode /tmp/eeprom
		if [ "$MAGIC" = "CHIP" ]; then :			
			echo "$VENDOR_NAME, $PRODUCT_NAME (v$PRODUCT_V)"
		else
			echo "Not a CHIP DIP EEPROM image"
		fi
		NR=$((NR+1))
	done
	MAX_EEPROM=$((NR-1))
}

decode() {
	MAGIC=`head -c 4 $1`
	if [ "$MAGIC" = "CHIP" ]; then :
		#echo "MAGIC"
		VENDOR_ID=`head -c 9 $1 | hexdump -C | sed -n 1p | cut -d " " -f 8,9,10,12`
		PRODUCT_ID=`head -c 11 $1 | hexdump -C | sed -n 1p | cut -d " " -f 13,14`
		PRODUCT_V=`head -c 12 $1 | hexdump -C | sed -n 1p | cut -d " " -f 15`
		VENDOR_NAME=`head -c 44 $1 | tail -c 32`
		PRODUCT_NAME=`head -c 67 $1 | tail -c 32`
		#echo "VENDOR_ID:"$VENDOR_ID
		#echo "PRODUC_ID:"$PRODUCT_ID
		#echo "PRODUCT_V:"$PRODUCT_V
		#echo "VENDOR_NAME:"$VENDOR_NAME
		#echo "PRODUCT_NAME:"$PRODUCT_NAME
		#echo "EOF Decode"
	else
		VENDOR_ID=
		PRODUCT_ID=
		PRODUCT_V=
		VENDOR_NAME=
		PRODUCT_NAME=
	fi
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
NR=
IMG_NAME=
IMG_FILE=
IMG_NR=999
EEPROM_NR=999
EEPROM_FILE=
MAX_EEPROM=
MAX_FILE=
modprobe w1_ds2431
confirm=""
REBOOT=""

while [[ $# -gt 0 ]]; do
	key="$1"

	case $key in
	    -y|--yes)
	    confirm="y"
	    ;;
	    -e|--eeprom)
	    EEPROM_NR="$2"
	    shift # past argument
	    ;;
	    -r|--reboot)
	    REBOOT="1"
	    ;;
	    -i|--img)
	    IMG_NR="$2"
	    shift # past argument
	    ;;
	    *)
	            # unknown option
	    ;;
	esac

	shift # past argument or value
done


echo ""
echo "Welcome to the CHIP EEPROM flasher tool"
echo "=========================="
echo "List of all connected ICs:"
list_sys
if [ $NR -gt 2 ]; then : # at least 2 found 
	if [ $EEPROM_NR -eq 999 ]; then :
		while [ $EEPROM_NR -gt $MAX_EEPROM ]; do
			echo -n "Which IC do you want to program > "
			read EEPROM_NR
		done
	else
		echo "Select EEPROM ($EEPROM_NR)"
	fi
else 
	echo "only one available, choosing (1)"
	EEPROM_NR=1
fi
echo ""
echo "=========================="
echo "List of all available images"
list_file
if [ $NR -gt 2 ]; then : # at least 2 found 
	if [ $IMG_NR -eq 999 ]; then :
		while [ $IMG_NR -gt $MAX_FILE ]; do
			echo -n "Which image do you want to flash > "
			read IMG_NR
		done
	else
		echo "Select image ($IMG_NR)"
	fi
else 
	echo "only one available, choosing (1)"
	IMG_NR=1
fi
echo ""
echo "=========================="

##### get image file for selected nr
NR=1
for f in $DIR/*.img; do :
	if [ $NR -eq $IMG_NR ]; then :
		IMG_FILE=$f
		decode $f
		IMG_NAME=$PRODUCT_NAME
	fi
	NR=$((NR+1))
done
##### get eeprom for selected nr
NR=1
for f in /sys/bus/w1/devices/*/eeprom; do :
	if [ $NR -eq $EEPROM_NR ]; then :
		EEPROM_FILE=$f
	fi
	NR=$((NR+1))
done

##### confirm 
while [ "$confirm" != "y" -a "$confirm" != "n" ]; do :
	E_SHORT=`echo $EEPROM_FILE|rev|cut -d "/" -f2|rev`
	echo -n "Please confirm to flash image \"$IMG_NAME\" to $E_SHORT (y/n) > "
	read confirm
done

##### flash
if [ "$confirm" = "y" ]; then :
	echo -n "Flashing "
	cat $IMG_FILE > $EEPROM_FILE; ST=$?
	if [ $ST -ne 0 ]; then :
	  echo "Flashing failed"
	 else
		echo "done"
	fi
fi

##### reboot
if [ "$REBOOT" = "1" ]; then :
	echo "rebooting now ..."
	sleep 2;
	sudo reboot now;
fi
