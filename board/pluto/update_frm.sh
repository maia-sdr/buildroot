#!/bin/sh

#set -x

source /etc/device_config

FRM_FILE="$1"

flash_indication_on() {
	echo timer > /sys/class/leds/led0:green/trigger
	echo 40 > /sys/class/leds/led0:green/delay_off
	echo 40 > /sys/class/leds/led0:green/delay_on
}

flash_indication_off() {
	echo heartbeat > /sys/class/leds/led0:green/trigger
}

handle_frimware_frm () {
	FILE="$1"
	MAGIC="$2"
	md5=`tail -c 33 ${FILE}`
	FRM_SIZE=`head -c -33 ${FILE} | wc -c | xargs printf "%X\n"`
	frm=`head -c -33 ${FILE} | md5sum | cut -d ' ' -f 1`
	if [ "$frm" = "$md5" ]
	then
		flash_indication_on
		grep -q "${MAGIC}" ${FILE} && dd if=${FILE} of=/dev/mtdblock3 bs=64k && fw_setenv fit_size ${FRM_SIZE} && echo "Done" || echo "Failed"
		flash_indication_off
		sync
		exit 0
	else
		echo Failed Checksum error: $frm $md5
		exit 1
	fi
}



if [[ -f ${FRM_FILE} ]] && [[ ${FRM_FILE: -4} == ".frm" ]] && [[ -s ${FRM_FILE} ]]
then
	handle_frimware_frm "${FRM_FILE}" "${FRM_MAGIC}"
else
	echo "Failed"
	exit 1
fi
