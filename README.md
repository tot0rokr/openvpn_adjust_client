# openvpn_adjust_client

A script for openvpn add/remove clients.

Caution!!: Openvpn config files are generated into `/home/ubuntu/targets/` and change owner to ubuntu.

## Pre-required

This script is available in openvpn docker created as follow commands.

```sh
docker pull kylemanna/openvpn

export SERVER_DOMAIN=[SERVER_DOMAIN]
export OVPN_DATA=/openvpn_data
docker run -v $OVPN_DATA:/etc/openvpn --rm kylemanna/openvpn ovpn_genconfig -u "udp://$SERVER_DOMAIN" -N -d
docker run -v $OVPN_DATA:/etc/openvpn --rm -it kylemanna/openvpn ovpn_initpki 	# Remember Pass Phase key
docker run -v $OVPN_DATA:/etc/openvpn -d -p 1194:1194/udp --name="ovpn" --restart="always" --cap-add=NET_ADMIN kylemanna/openvpn
```

And store 'Pass Phase Key' into passwd.txt (You can change name if you want)

This scripts use [sexpect](https://github.com/clarkwang/sexpect) module.
So, Install the module first.

You can change parameters at the top of the scripts.

## Usage

```sh
$ ./add_client {network} {name} [{start index=1} [count=1]]
$ ./remove_client {name} [{start index=1} [count=1]]

```

## Example

```sh
$ ./add_client 192.168.0.0 test 1 5
$ ./remove_client test 2 3
```

Only clients test1 and test5 remain.


---

And, Enjoy.
