# Common commands
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf


# Default GW of Machine
default via 10.0.2.1 dev enp0s3 proto dhcp src 10.0.2.15 metric 101
default via 10.0.3.1 dev enp0s9 proto dhcp src 10.0.3.4 metric 103


# routing table commands

ip route show all
ip route show table name
ip ruoute flush table name
ip route del default
ip route get to 8.8.8.8



ip rule show all
ip rule show table name
ip rule flush table name

## Tun1 route
echo '206 TUN1' >> /etc/iproute2/rt_tables
ip rule add from 10.10.10.0/24 table TUN1
ip route add default via 10.10.20.100 dev t1-wan table TUN1
ip route add 10.10.10.0/24 via 10.10.20.100 dev t1-wan table TUN1
ip route add default dev t1-wan table TUN1

## Additonal
sudo firewall-cmd --zone=tun-lan --change-interface=t1-lan
sudo firewall-cmd --set-log-denied=all
sudo journalctl -xe

## Add Zone
firewall-cmd --permanent --new-zone=tun-lan
firewall-cmd --permanent --new-zone=tun-wan
firewall-cmd --reload

## Remove Zone
firewall-cmd --permanent --delete-zone=tun-lan
firewall-cmd --permanent --delete-zone=tun-wan
firewall-cmd --reload


## Add interface
sudo firewall-cmd --zone=tun-lan --add-interface=t1-lan --permanent
sudo firewall-cmd --zone=tun-wan --add-interface=t1-wan --permanent
sudo firewall-cmd --reload

## Remove interface
sudo firewall-cmd --zone=tun-lan --remove-interface=t1-lan --permanent
sudo firewall-cmd --zone=tun-wan --remove-interface=t1-wan --permanent
sudo firewall-cmd --reload


# Public Zone
# sudo firewall-cmd --add-interface=t1-lan --permanent
# sudo firewall-cmd --add-interface=t1-wan --permanent
# sudo firewall-cmd --reload
sudo firewall-cmd --add-masquerade --permanent
sudo firewall-cmd --add-forward --permanent
sudo firewall-cmd --permanent --add-protocol=icmp
sudo firewall-cmd --permanent --add-port=51820/udp
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload

## Zone Details
sudo firewall-cmd --get-zones
sudo firewall-cmd --list-all
sudo firewall-cmd --zone=tun-lan --list-all
sudo firewall-cmd --zone=tun-wan --list-all


# tun-lan 
sudo firewall-cmd --zone=tun-lan --add-masquerade --permanent
sudo firewall-cmd --zone=tun-lan --set-target=DROP --permanent
sudo firewall-cmd --zone=tun-lan --add-forward --permanent
sudo firewall-cmd --permanent --zone=tun-lan --add-protocol=icmp
sudo firewall-cmd --reload

# Custom service on tun-lan
firewall-cmd --permanent --zone=tun-lan --add-service=http
firewall-cmd --permanent --zone=tun-lan --add-service=https
firewall-cmd --permanent --zone=tun-lan --add-service=dns


# wan-tun
sudo firewall-cmd --zone=tun-wan --add-masquerade --permanent
sudo firewall-cmd --zone=tun-wan --set-target=default --permanent
sudo firewall-cmd --zone=tun-wan --add-forward --permanent
sudo firewall-cmd --permanent --zone=tun-wan --add-protocol=icmp
sudo firewall-cmd --reload

# Custom service on tun-wan
firewall-cmd --permanent --zone=tun-wan --add-service=http
firewall-cmd --permanent --zone=tun-wan --add-service=https
firewall-cmd --permanent --zone=tun-wan --add-service=dns

## Filter at wan
sudo firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 0 -i t1-lan -o t1-wan -p tcp --dport 443 -j ACCEPT
sudo firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 1 -i t1-lan -o t1-wan -j DROP
sudo firewall-cmd --reload



## Temp
sudo firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 0 -i t1-lan -o t1-wan -p icmp -j ACCEPT

sudo firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 0 -i t1-lan -o t1-wan -j ACCEPT
sudo firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 1 -i t1-wan -o t1-lan -j ACCEPT
sudo firewall-cmd --reload


sudo firewall-cmd --zone=tun-lan --add-rich-rule='rule family=ipv4 source address=10.10.10.0/24 forward to zone=tun-wan accept' --permanent
sudo firewall-cmd --zone=tun-wan --add-rich-rule='rule family=ipv4 source address=10.10.10.0/24 forward to zone=tun-lan accept' --permanent
sudo firewall-cmd --reload



sudo nft add rule ip filter FORWARD iif "t1-lan" oif "t1-wan" counter
sudo nft add rule ip filter FORWARD iif "t1-wan" oif "t1-lan" counter
sudo firewall-cmd --reload


sudo firewall-cmd --add-interface=t1-wan --permanent



# Custom service on tun-lan
firewall-cmd --permanent --zone=tun-lan --add-service=http
firewall-cmd --permanent --zone=tun-lan --add-service=https
firewall-cmd --permanent --zone=tun-lan --add-service=dns


# Allow established connections
firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 0 -i lan_tun -o wan_tun -m state --state ESTABLISHED,RELATED -j ACCEPT


ip route add 10.10.10.0/24 via 10.10.20.100 dev t1-wan table TUN1



# Verify configuration
echo "Verifying configuration..."
echo "Zones:"
firewall-cmd --list-all-zones
echo "Policies:"
firewall-cmd --list-policies
echo "Policy details:"
firewall-cmd --info-policy lanwantunpolicy
echo "Routes:"
ip route show


firewall-cmd --permanent --new-policy lanwantunpolicy
firewall-cmd --permanent --policy lanwantunpolicy --add-ingress-zone=tun-lan
firewall-cmd --permanent --policy lanwantunpolicy --add-egress-zone=tun-wan
firewall-cmd --permanent --policy lanwantunpolicy --set-target=ACCEPT
sudo firewall-cmd --reload


sudo firewall-cmd --zone=tun-lan --ad-interface=t1-wan
sudo firewall-cmd --reload


sudo firewall-cmd --permanent --add-interface=t1-wan
sudo firewall-cmd --reload


sudo firewall-cmd --permanent --zone=tun-lan --add-protocol=udp
sudo firewall-cmd --permanent --zone=tun-lan --add-protocol=tcp
sudo firewall-cmd --reload

sudo firewall-cmd --permanent --zone=tun-lan --add-port=53/udp
sudo firewall-cmd --permanent --add-port=443/udp
sudo firewall-cmd --reload


firewall-cmd --permanent --zone=tun-lan --del-rich-rule='rule family=ipv4 source address="10.10.10.0/24" accept'



sudo firewall-cmd --permanent --zone=tun-wan --remove-service=http
sudo firewall-cmd --permanent --zone=tun-wan --remove-service=dns
sudo firewall-cmd --permanent --zone=tun-wan --remove-service=https
sudo firewall-cmd --permanent --zone=tun-wan --remove-protocol=icmp



firewall-cmd --permanent --zone=tun-lan --add-port=443/tcp
firewall-cmd --permanent --zone=tun-lan --add-port=443/udp
firewall-cmd --permanent --zone=tun-lan --add-port=53/tcp
firewall-cmd --permanent --zone=tun-lan --add-port=53/udp
firewall-cmd --permanent --zone=tun-lan --add-port=80/tcp
firewall-cmd --reload





PostUp = iptables -I FORWARD 1 -i t1-lan -j ACCEPT; iptables -t nat -A POSTROUTING -o t1-wan -j MASQUERADE
PostDown = iptables -D FORWARD  -i t1-lan -j ACCEPT; iptables -t nat -D POSTROUTING -o t1-wan -j MASQUERADE


PostUp = nft 'add rule inet filter forward iifname "t1-lan" counter accept'; nft 'add rule inet nat postrouting oifname "t1-wan" counter masquerade'
PostDown = nft 'delete rule inet filter forward handle $(nft -a list chain inet filter forward | grep "iifname \"t1-lan\"" | cut -d "#" -f 2)'; nft 'delete rule inet nat postrouting handle $(nft -a list chain inet nat postrouting | grep "oifname \"t1-wan\"" | cut -d "#" -f 2)'


PostUp = nft 'add rule inet filter forward iifname "t1-lan" counter accept'; nft 'add rule inet nat postrouting oifname "t1-wan" counter masquerade'

# PostDown rules in nftables format:
PostDown = nft 'delete rule inet filter forward handle $(nft -a list chain inet filter forward | grep "iifname \"t1-lan\"" | cut -d "#" -f 2)'; nft 'delete rule inet nat postrouting handle $(nft -a list chain inet nat postrouting | grep "oifname \"t1-wan\"" | cut -d "#" -f 2)'




VPS
======================
Username : root
Password : Ez4qFmSg3NSvH1A
IP : 147.182.175.95
Rev cmd :  nc -nlvp 443


[Interface]
Address = 10.10.20.102/24
ListenPort = 443
PrivateKey = CAONcHy7KIYUq+dBC5egfCDg+bucNTWTVhb7SEPu11o=

PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE


[Peer]
PublicKey = mMltk9JkeQgnul8P+biO/EUWyZ1egvEsP6ICREJ3ExY=
AllowedIPs = 10.10.20.101/32



PostUp = iptables -I FORWARD 1 -i t1-lan -o ti-wan -p udp --dport 53 -j ACCEPT; iptables -I FORWARD 2 -i t1-lan -o ti-wan -p tcp --dport 53 -j ACCEPT; iptables -I FORWARD 3 -i t1-lan -o ti-wan -p tcp --dport 443 -j ACCEPT; iptables -I FORWARD 4 -i t1-lan -o ti-wan -j DROP; iptables -t nat -A POSTROUTING -o ti-wan -j MASQUERADE; iptables -A FORWARD -i ti-wan -o t1-lan -m state --state RELATED,ESTABLISHED -j ACCEPT
PostDown = iptables -D FORWARD -i t1-lan -o ti-wan -p udp --dport 53 -j ACCEPT; iptables -D FORWARD -i t1-lan -o ti-wan -p tcp --dport 53 -j ACCEPT; iptables -D FORWARD -i t1-lan -o t1-wan -p tcp --dport 443 -j ACCEPT; iptables -D FORWARD -i t1-lan -o t1-wan -j DROP; iptables -t nat -D POSTROUTING -o t1-wan -j MASQUERADE; iptables -D FORWARD -i t1-wan -o t1-lan -m state --state RELATED,ESTABLISHED -j ACCEPT


sudo nft add table inet filter
sudo nft add chain inet filter input '{ type filter hook input priority 0\; policy accept\; }'

sudo nft add chain inet filter input '{ type filter hook input priority 0 \; policy accept \; }'
sudo nft add rule inet filter input iifname "enp0s8" udp dport 51820 drop
sudo nft list ruleset


sudo firewall-cmd --set-log-denied=all
sudo journalctl -f | grep 'DENIED'



firewall-cmd --permanent --zone=public --remove-forward-port=port=0-65535:proto=tcp:toport=0-65535:toaddr=10.10.20.100
firewall-cmd --permanent --zone=public --remove-forward-port=port=0-65535:proto=udp:toport=0-65535:toaddr=10.10.20.100
sudo firewall-cmd --reload


echo '207 internet1' >> /etc/iproute2/rt_tables
ip rule add from 10.10.20.0/24 table internet1
ip route add default dev t1-wan table internet1



ip rule add from 10.10.10.0/24 table TUN1
ip route add default via 10.10.20.100 dev t1-wan table TUN1

ip rule add from 0.0.0.0/0 table internet1
ip route add default via 10.10.20.100 dev t1-wan table internet1



wg set t1-wan fwmark 51820
ip -4 route add 0.0.0.0/0 dev t1-wan table 51820
ip -4 rule add not fwmark 51820 table 51820

 
ip -4 rule add table main suppress_prefixlength 0
sysctl -q net.ipv4.conf.all.src_valid_mark=1


# This will route traffice from lan tunnel to wan tunnel 
ip rule add iif lan-t1 table 123 priority 206
ip -4 route add 10.10.20.100/32 dev wan-t1 table 123
ip -4 route add 0.0.0.0/0 dev wan-t1 table 123



ip rule add iif t1-wan table 124 priority 207
ip -4 route add 10.0.2.15/32 dev enp0s3 table 124
ip -4 route add 0.0.0.0/0 dev enp0s3 table 124


firewall-cmd --permanent --zone=tun-lan --add-forward --zone=tun-wan
firewall-cmd --permanent --zone=tun-wan --add-forward --zone=tun-lan
firewall-cmd --permanent --zone=tun-lan --add-port=53/udp
firewall-cmd --permanent --zone=tun-lan --add-port=53/tcp
firewall-cmd --permanent --zone=tun-wan --add-port=53/udp
firewall-cmd --permanent --zone=tun-wan --add-port=53/tcp

# Enable masquerading on WAN zone
firewall-cmd --permanent --zone=t1wan --add-masquerade

# Enable zone forwarding from t1lan to t1wan
sudo firewall-cmd --permanent --zone=tun-lan --set-target=default
firewall-cmd --permanent --zone=tun-lan --add-forward-port=port=1-65535:proto=tcp:toport=1-65535:tozone=tun-wan
firewall-cmd --permanent --zone=tun-lan --add-forward-port=port=1-65535:proto=udp:toport=1-65535:tozone=tun-wan
firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 0 -i t1-lan -o t1-wan -j ACCEPT
firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 0 -i t1-wan -o t1-lan -m state --state RELATED,ESTABLISHED -j ACCEPT
firewall-cmd --reload


firewall-cmd --permanent --zone=tun-lan --remove-rich-rule='rule family="ipv4" port port="8000" protocol="tcp" reject'



PostUp = iptables -A FORWARD 0 -i t1-lan -j ACCEPT; iptables -t nat -A POSTROUTING -o t1-wan -j MASQUERADE; iptables -A FORWARD 1 -i t1-wan -o t1-lan -m state --state RELATED,ESTABLISHED -j ACCEPT
PostDown = iptables -D FORWARD -i t1-lan -j ACCEPT; iptables -t nat -D POSTROUTING -o t1-wan -j MASQUERADE; iptables -D FORWARD -i tun1 -o t1-lan -m state --state RELATED,ESTABLISHED -j ACCEPT



PostUp = iptables -A FORWARD -i t1-lan -j ACCEPT; iptables -t nat -A POSTROUTING -o t1-wan -j MASQUERADE; iptables -A FORWARD -i t1-wan -o t1-lan -m state --state RELATED,ESTABLISHED -j ACCEPT; iptables -I FORWARD -i t1-lan -o t1-wan -p tcp --dport 8000 -j DROP
PostDown = iptables -D FORWARD -i t1-lan -j ACCEPT; iptables -t nat -D POSTROUTING -o t1-wan -j MASQUERADE; iptables -D FORWARD -i t1-wan -o t1-lan -m state --state RELATED,ESTABLISHED -j ACCEPT; iptables -D FORWARD -i t1-lan -o t1-wan -p tcp --dport 8000 -j DROP



PostUp = iptables -I FORWARD 1 -i wg0 -o tun1 -p udp --dport 53 -j ACCEPT; iptables -I FORWARD 3 -i wg0 -o tun1 -p tcp --dport 443 -j ACCEPT; iptables -I FORWARD 4 -i wg0 -o tun1 -j DROP; iptables -t nat -A POSTROUTING -o tun1 -j MASQUERADE; iptables -A FORWARD -i tun1 -o wg0 -m state --state RELATED,ESTABLISHED -j ACCEPT
PostDown = iptables -D FORWARD -i wg0 -o tun1 -p udp --dport 53 -j ACCEPT; iptables -D FORWARD -i wg0 -o tun1 -p tcp --dport 443 -j ACCEPT; iptables -D FORWARD -i wg0 -o tun1 -j DROP; iptables -t nat -D POSTROUTING -o tun1 -j MASQUERADE; iptables -D FORWARD -i tun1 -o wg0 -m state --state RELATED,ESTABLISHED -j ACCEPT

iptables -I FORWARD 1 -i t1-lan -o t1-wan -p udp --dport 53 -j ACCEPT; 
iptables -I FORWARD 3 -i t1-lan -o t1-wan -p tcp --dport 443 -j ACCEPT; 
iptables -I FORWARD 4 -i t1-lan -o t1-wan -j DROP; 
iptables -t nat -A POSTROUTING -o t1-wan -j MASQUERADE; 
iptables -A FORWARD -i t1-wan -o t1-lan -m state --state RELATED,ESTABLISHED -j ACCEPT




firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 1 -i t1-lan -o t1-wan -j ACCEPT
firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 2 -i t1-lan -o t1-wan -p tcp --dport 8000 -j DROP
firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD -i t1-wan -o t1-lan -m state --state RELATED,ESTABLISHED -j ACCEPT


firewall-cmd --permanent --direct --remove-rule ipv4 filter FORWARD 1 -i t1-lan -j ACCEPT
firewall-cmd --permanent --direct --remove-rule ipv4 filter FORWARD 2 -i t1-wan -o t1-lan -m state --state RELATED,ESTABLISHED -j ACCEPT



firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 1 -i t1-lan -o t1-wan -p udp --dport 53 -j ACCEPT
firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 2 -i t1-lan -o t1-wan -p tcp --dport 443 -j ACCEPT
firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 3 -i t1-lan -o t1-wan -p tcp --dport 80 -j ACCEPT
firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 4 -i t1-lan -o t1-wan -p icmp -j ACCEPT
firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 5 -i t1-wan -o t1-lan -p icmp -j ACCEPT
firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 6 -i t1-wan -o t1-lan -m state --state RELATED,ESTABLISHED -j ACCEPT
firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 7 -i t1-lan -o t1-wan -j DROP



firewall-cmd --direct --get-all-rules
firewall-cmd --permanent --direct --remove-all-rules



firewall-cmd --permanent --direct --remove-rule ipv4 filter FORWARD 1 -i t1-lan -o t1-wan -j ACCEPT
firewall-cmd --permanent --direct --remove-rule ipv4 filter FORWARD 2 -i t1-wan -o t1-lan -m state --state RELATED,ESTABLISHED -j ACCEPT
firewall-cmd --permanent --direct --remove-rule ipv4 filter FORWARD 2 -i t1-lan -o t1-wan -p tcp --dport 8000 -j DROP




sudo firewall-cmd --permanent --new-policy=drop_tun
sudo firewall-cmd --permanent --policy=drop_tun --add-ingress-zone=tun-lan
sudo firewall-cmd --permanent --policy=drop_tun --add-ingress-zone=tun-lan2
sudo firewall-cmd --permanent --policy=drop_tun --add-egress-zone=public
sudo firewall-cmd --permanent --policy=drop_tun --set-target=DROP
sudo firewall-cmd --reload
watch -n1 "ip route get 8.8.8.8"



# Add routes for WAN 1
ip route add default via 192.168.10.254 dev wan-t1 table wan1
ip route add 192.16.10.0/24 dev wan-t1 table wan1

# Add routes for WAN 2
ip route add default via 172.16.0.254 dev wan-t2 table wan2
ip route add 172.16.0.0/24 dev wan-t2 table wan2


# Route traffic from t1-wan through WAN 1
ip rule add iif wan-t1 table wan1 priority 100

# Route traffic from t2-wan through WAN 2
ip rule add iif t2-wan table wan2 priority 101

ip rule add iif lan-t1 table 123 priority 206
ip -4 route add 10.10.20.100/32 dev wan-t1 table 123
ip -4 route add 0.0.0.0/0 dev wan-t1 table 123


ip rule add iif wan-t1 table 321 priority 100
ip -4 route add 10.0.3.4/32 dev enp0s9 table 321
ip -4 route add 0.0.0.0/0 dev enp0s9 table 321

ip -4 route add 10.0.2.15/32 dev enp0s3 table 321
ip -4 route add 0.0.0.0/0 dev enp0s3 table 321
ip route add default via 10.0.2.15 dev enp0s3 table 321



ip rule add iif enp0s3 table 321 priority 100 
sudo ip route add 0.0.0.0/0 dev enp0s9 table 321
sudo ip route add 10.0.2.0/24 dev enp0s9 table 321

sudo ip route add 0.0.0.0/0 dev enp0s9 table t1-wan
sudo ip route add 10.0.3.0/24 dev enp0s9 src 10.0.2.15 table t1-wan

ip rule add from 10.10.20.100/29 table 321
ip route add 147.182.175.95/32 via 10.0.3.1 dev enp0s9 table 321 
ip route add default via 10.0.3.1 dev enp0s9 table 321


# This will route traffice from lan tunnel to wan tunnel 
ip rule add iif wan-t1 table 321 priority 100
ip -4 route add 10.0.3.4/32 dev enp0s9 table 321
ip -4 route add 0.0.0.0/0 dev enp0s9 table 321


sudo firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 1 -i lan-t1 -o wan-t1 -p icmp -j ACCEPT
sudo firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 1 -i wan-t1 -o lan-t1 -p icmp -j ACCEPT


sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source zone="lan-zone" destination zone="wan-zone" service name="icmp" accept'
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source zone="wan-zone" destination zone="lan-zone" service name="icmp" accept'


sudo firewall-cmd --permanent --zone=lan-zone --remove-icmp-block=echo-request
sudo firewall-cmd --permanent --zone=lan-zone --remove-icmp-block=echo-reply
sudo firewall-cmd --permanent --zone=lan-zone --remove-icmp-block=time-exceeded
sudo firewall-cmd --reload


firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 7 -i lan-t1 -o wan-t1 -p udp --dport 33434:33534 -j ACCEPT
firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 7 -i wan-t1 -o lan-t1 -p udp --dport 33434:33534 -j ACCEPT


# Test routing for traffic from WG1
ip route get 8.8.8.8 from $(ip -4 addr show dev lan-t1 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

# Test routing for traffic from WG2
ip route get 8.8.8.8 from $(ip -4 addr show dev wg2-lan | grep -oP '(?<=inet\s)\d+(\.\d+){3}')



default via 10.0.2.1 dev enp0s3 proto dhcp src 10.0.2.15 metric 101
default via 10.0.3.1 dev enp0s9 proto dhcp src 10.0.3.4 metric 103






lan-t1(wirguard interface) -------> wan-t1(wirguard interface) -----> enp0s3 (physical interface internet)
lan-t2(wirguard interface) -------> wan-t2(wirguard interface) -----> enp0s9 (physical interface internet)



ip route add 147.182.175.95 via 10.0.3.1 dev enp0s9

ip rule add iif wan-t1 table 124 priority 207
ip route add 0.0.0.0/0 dev enp0s3 table 124
