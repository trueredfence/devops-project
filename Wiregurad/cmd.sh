# Firewall of all host
port open then
sudo firewall-cmd --zone=public --add-masquerade --permanent
sudo firewall-cmd --zone=public --remove-masquerade --permanent
firewall-cmd --zone=public --remove-masquerade

sudo ip route add 17.16.10.0/24 dev wg0





ip route del default via 17.16.0.0/24 dev wg0




sudo ip route add 17.16.10.0/24 dev wg0
sudo ip route add default 17.16.0.0/24 dev wg0
sudo ip route add default via 17.16.0.2 dev wg0 # Don't Use this command

sudo ip route add default via 17.16.0.3 dev wg0 # Don't use this commnad



sudo /sbin/ip route add default dev wg0 table 123

sudo /sbin/ip rule add from 172.16.0.0/24 table 123
sudo /sbin/iptables -t nat -A POSTROUTING -o wg0 -j MASQUERADE
sudo /sbin/iptables -t nat -A POSTROUTING -o enp0s8 -j MASQUERADE

PostUp = iptables -A FORWARD -i wg0 -j ACCEPT 
PostUP = iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT
PostDown = iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

