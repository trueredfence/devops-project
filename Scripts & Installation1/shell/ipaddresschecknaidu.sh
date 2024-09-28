#!/bin/bash
declare -A ipaddress
ipaddress[192.168.10.81]='CNC for god'


if [[ ! -z ${ipaddress[$1]} ]]; then
    echo "IP ${1} now used for ${ipaddress[$1]}";
else
	echo "IP ${1} not found";
fi