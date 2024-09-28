#!/bin/bash
if ping -q -c 1 -W 1 8.8.8.8 >/dev/null; then firewall-cmd --direct --add-rule ipv4 filter OUTPUT 1 -d 192.168.12.50 -j DROP; else systemctl restart firewalld.service; fi;