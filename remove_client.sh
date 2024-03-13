#!/bin/bash
# Removes clients.

PW_FILE="passwd.txt"
OVPN_DATA=/openvpn_data
CCD_PATH="$OVPN_DATA/ccd"
TARGET_DIR=/home/ubuntu/targets

if [ $# -lt 1 ]; then
	echo "[USAGE] $0 {name} [{start_index} [{count}]]"
	echo "Description: "
	echo "    Index starts from 1."
	echo "    \"${PW_FILE}\" file must exist in current directory. No contain carriage return."
	exit -1
fi

export SEXPECT_SOCKFILE=/tmp/sexpect-$$.sock

# Run openvpn service when it is not running.
if [ $(docker ps -f "name=ovpn" -f "status=running" | wc -l) -ne 2 ]; then
	docker run -v $OVPN_DATA:/etc/openvpn -d -p 1194:1194/udp --name="ovpn" --restart="always" --cap-add=NET_ADMIN kylemanna/openvpn
fi

# Make directory
if [ ! -e "$TARGET_DIR" ]; then
	mkdir $TARGET_DIR
fi

# password file should exist.
if [ ! -e ${PW_FILE} ]; then
	echo "\"${PW_FILE}\" file not found"
	exit -1
fi

# Parse arguments.
NAME=$1

if [ $# -gt 1 ]; then
	START_INDEX=$2
else
	START_INDEX=1
fi

if [ $# -gt 2 ]; then
	COUNT=$3
	END_INDEX=$(($START_INDEX + $COUNT - 1))
else
	END_INDEX=$START_INDEX
fi


for i in $(seq $START_INDEX $END_INDEX); do
	client_name="${NAME}${i}"

	if [ -e "$CCD_PATH/$client_name" ]; then
		rm "$CCD_PATH/$client_name"
	fi

	if [ -e "$TARGET_DIR/${client_name}.ovpn" ]; then
		rm "$TARGET_DIR/${client_name}.ovpn"
	fi

	sexpect spawn -idle 10 docker run -it -v $OVPN_DATA:/etc/openvpn --rm kylemanna/openvpn ovpn_revokeclient $client_name remove

	if sexpect expect -t 2 -re "Continue with revocation"; then
		sexpect send -cr "yes"
		if sexpect expect -t 2 -re "Enter pass phrase"; then
			cat $PW_FILE | xargs sexpect send -cr
		fi
		if sexpect expect -t 2 -re "Enter pass phrase"; then
			cat $PW_FILE | xargs sexpect send -cr
		fi
	fi
	sexpect wait

	echo "Complete remove $client_name"
done
