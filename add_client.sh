#!/bin/bash
# Add clients.

PW_FILE="passwd.txt"
OVPN_DATA=/openvpn_data
CCD_PATH="$OVPN_DATA/ccd"
TARGET_DIR=/home/ubuntu/targets

if [ $# -lt 2 ]; then
	echo "[USAGE] $0 {network} {name} [{start_index} [{count}]]"
	echo "Description: "
	echo "    Index starts from 1."
	echo "    \"${PW_FILE}\" file must exist in current directory. No contain carriage return."
	exit -1
fi

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
NETWORK=$1
NETWORK_1=$(echo $NETWORK | cut -d '.' -f1)
NETWORK_2=$(echo $NETWORK | cut -d '.' -f2)
NETWORK_3=$(echo $NETWORK | cut -d '.' -f3)
NETWORK_4=$(echo $NETWORK | cut -d '.' -f4)
NAME=$2

if [ $# -gt 2 ]; then
	START_INDEX=$3
else
	START_INDEX=1
fi

if [ $# -gt 3 ]; then
	COUNT=$4
	END_INDEX=$(($START_INDEX + $COUNT - 1))
else
	END_INDEX=$START_INDEX
fi

# Error when overflow network mask.
if [ $(($NETWORK_3 + $END_INDEX * 4 / 0x100)) -gt $((0xFF)) ]; then
	echo "Overflow network range"
	exit -2
fi

for i in $(seq $START_INDEX $END_INDEX); do
	client_name="${NAME}$(printf %02d ${i})"

	if [ -e "$CCD_PATH/$client_name" ]; then
		echo "Already $client_name user exist."
		exit -3
	fi

	docker run -v $OVPN_DATA:/etc/openvpn --rm -i kylemanna/openvpn easyrsa build-client-full "$client_name" nopass < $PW_FILE
	docker run -v $OVPN_DATA:/etc/openvpn --rm -it kylemanna/openvpn ovpn_getclient "$client_name" > "$TARGET_DIR/${client_name}.ovpn"
	chown ubuntu:ubuntu "$TARGET_DIR/${client_name}.ovpn"

	network_index=
	network_4=$((${NETWORK_4} + (${i} - 1) * 4 % 0x100))
	network_3=$((${NETWORK_3} + (${i} - 1) * 4 / 0x100))
	network_2=$NETWORK_2
	network_1=$NETWORK_1

	ccd="\
iroute ${network_1}.${network_2}.${network_3}.${network_4} 255.255.255.252\n\
ifconfig-push ${network_1}.${network_2}.${network_3}.$(($network_4 + 2)) ${network_1}.${network_2}.${network_3}.$(($network_4 + 1))\n\
\n\
push \"route 10.99.99.0 255.255.255.0\""

	echo -e $ccd > "$CCD_PATH/$client_name"

	echo "Complete add $client_name"
done
