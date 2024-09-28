# Userful firewall and iptables command to work with wireguard

```bash

sudo firewall-cmd --permanent --zone=public --add-rich-rule='rule family="ipv4" port port="80" protocol="tcp" drop'
sudo firewall-cmd --permanent --zone=public --add-rich-rule='rule family="ipv4" source interface="wg0" port protocol="tcp" port="443" reject'
sudo firewall-cmd --permanent --zone=public --add-rich-rule='rule family="ipv4" source interface="tun1" port protocol="tcp" port="443" reject' && \
sudo firewall-cmd --reload

sudo firewall-cmd --permanent --zone=wireguard --remove-interface=wg0
sudo firewall-cmd --permanent --zone=public --add-interface=wg0
firewall-cmd --permanent --zone=public --add-interface=wg0
# Create Zone and add interface on firewalld


firewall-cmd --get-zones


sudo firewall-cmd --permanent --new-zone=wgincome && \
sudo firewall-cmd --permanent --zone=wgincome --add-interface=wg0 && \
sudo firewall-cmd --permanent --zone=wgincome --add-masquerade && \
sudo firewall-cmd --permanent --zone=wgincome --add-forward && \
firewall-cmd --permanent --zone=wgincome --add-rich-rule='rule family="ipv4" port port="80" protocol="tcp" drop'  && \


sudo firewall-cmd --permanent --zone=wgincoming --set-target=ACCEPT && \
sudo firewall-cmd --permanent --zone=wgincoming --add-source=172.168.1.0/24 && \


sudo firewall-cmd --permanent --zone=wgincome --add-port=443/udp
sudo firewall-cmd --permanent --zone=wgincome --add-port=444/udp
sudo firewall-cmd --permanent --zone=wgincome --add-port=51820/udp
sudo firewall-cmd --permanent --delete-zone=wgincoming
sudo firewall-cmd --permanent --delete-zone=wgincome
sudo firewall-cmd --permanent --delete-zone=wireguard
sudo firewall-cmd --reload


sudo firewall-cmd --permanent --zone=public --add-port=8080/tcp
sudo firewall-cmd --permanent --zone=public --add-port=444/udp
sudo firewall-cmd --permanent --zone=public --add-port=51820/udp

sudo firewall-cmd --permanent --zone=wireguard --remove-rich-rule='rule family="ipv4" port port="443" protocol="tcp" drop'


sudo nmcli connection modify wg0 ipv4.dns "8.8.8.8 8.8.4.4 1.1.1.1"
sudo nmcli connection modify wg0 ipv4.dns-search ""
sudo nmcli connection modify wg0 ipv4.ignore-auto-dns yes
sudo systemctl restart NetworkManager



# This is the command line work for filtering
iptables -A FORWARD -i wg0 -j ACCEPT
iptables -t nat -A POSTROUTING -o tun1 -j MASQUERADE
iptables -I FORWARD -i wg0 -o tun1 -p tcp --dport 8080 -j DROP
or
iptables -A FORWARD -i wg0 -o tun1 -p tcp --dport 8080 -j DROP
iptables -A FORWARD -i tun1 -o wg0 -m state --state RELATED,ESTABLISHED -j ACCEPT


# This is the command line work for filtering
iptables -D FORWARD -i wg0 -j ACCEPT
iptables -t nat -D POSTROUTING -o tun1 -j MASQUERADE
iptables -D FORWARD -i wg0 -o tun1 -p tcp --dport 8080 -j DROP
iptables -D FORWARD -i tun1 -o wg0 -m state --state RELATED,ESTABLISHED -j ACCEPT




iptables -P FORWARD DROP

iptables -I FORWARD -i wg0 -j DROP
iptables -t nat -A POSTROUTING -o tun1 -j MASQUERADE
iptables -A FORWARD -i wg0 -o tun1 -p tcp --dport 8080 -j ACCEPT
iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT


iptables -P FORWARD ACCEPT
iptables -D FORWARD -i wg0 -j DROP
iptables -t nat -D POSTROUTING -o tun1 -j MASQUERADE
iptables -D FORWARD -i wg0 -o tun1 -p tcp --dport 8080 -j ACCEPT
iptables -D FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT



iptables -A FORWARD -i wg0 -o tun1 -j LOG --log-prefix "WG0 to TUN1: "
```
