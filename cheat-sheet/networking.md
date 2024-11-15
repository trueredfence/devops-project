# Networking and Routing Cheate sheet

## IP route

Understand IP Routes

### basic Cmds

```bash
ip route get 8.8.8.8 #to check which path system will take to go to 8.8.8.8
ip route get 8.8.8.8 fibmatch
ip route get 8.8.8.8 from 10.10.10.1 fibmatch
ip route show all # Get all routing detila
ip route show table 123 # get routing inside a table
ip route show scope host table all # host scope routing details local
ip route show scope link table all # link scope routing details connected network
ip route show scope global table all # global scope routing detail for rest all
```

### Note most specif network wins

```bash
ip route add 1.1.1.1 via 192.168.10.1
ip route add 1.1.1.0/24 via 192.168.10.2
ip route add default via 192.168.10.3
```

### based on matrix if two routes add

```bash
ip route add 1.1.1.1 via 192.168.10.1 metric 100
ip route add 1.1.1.1 via 192.168.10.2 metric 200
```

## IP Rules

Basic command for ip rules

### Firewall marks

```bash
ip rule add <fwmark> table 124 # Table for firewall packet marked
ip rule add lookup main suppress_prefixlength 0 # If local route not accessable due to ip rule table
ip rule add from 10.10.20.100/29 table 321
ip rule add from 192.168.157.3 table 321
```

## Other Example with Ip rule and route

```bash
# Add into 321 table with priortiy table
ip rule add iif lan-t1 table 321 priority 100
ip -4 route add 10.0.3.4/32 dev enp0s9 table 321
ip -4 route add 0.0.0.0/0 dev enp0s9 table 321
# metrix
ip route add default via 10.0.2.1 dev enp0s9 proto static metric 100 table default
```

## Other Commands

```bash
ip -4 -br a  # Get ip and interface status
ip -4 -br a  s dev eth0 # Get ip and interface status of select interface
host -t A ifconfig.me
traceroute -n 8.8.8.8
```

## Network Manager

Basic Commands for Network manager

### nmcli Connection & device cmd

```bash
nmcli connection show
nmcli connection show --active
nmcli -f NAME,TYPE,UUID connection show
nmcli connection up enp0s10
nmcli connection down eth1
nmcli connection modify enp0s10 ipv4.addresses 192.168.157.3/24
nmcli connection modify enp0s10 ipv4.method manual
nmcli connection modify enp0s10 ipv4.gateway 10.0.2.1
nmcli device status
```
