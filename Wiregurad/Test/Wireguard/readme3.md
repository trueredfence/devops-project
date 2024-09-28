```bash
# /etc/wireguard/wg0.conf
[Interface]
Address = 17.16.0.1/24
PrivateKey = <hope1_private_key>
ListenPort = 51820

PreUp = sysctl -w net.ipv4.ip_forward=1
PreUp = firewall-cmd --zone=public --add-port=51820/udp
PreUp = firewall-cmd --zone=public --add-masquerade

PostUp = ip route add 17.16.0.0/24 dev %i
PostUp = ip route add default via 17.16.0.2 dev %i

PostDown = ip route del 17.16.0.0/24 dev %i
PostDown = ip route del default via 17.16.0.2 dev %i
PostDown = firewall-cmd --zone=public --remove-port=51820/udp
PostDown = firewall-cmd --zone=public --remove-masquerade

[Peer]
PublicKey = <hope2_public_key>
AllowedIPs = 17.16.0.0/24
Endpoint = <hope2_public_ip>:51820
PersistentKeepalive = 25
```
```bash
# /etc/wireguard/wg0.conf
[Interface]
Address = 17.16.0.2/24
PrivateKey = <hope2_private_key>
ListenPort = 51820

PreUp = sysctl -w net.ipv4.ip_forward=1
PreUp = firewall-cmd --zone=public --add-port=51820/udp
PreUp = firewall-cmd --zone=public --add-masquerade

PostUp = ip route add 17.16.0.1/32 dev %i
PostUp = ip route add 17.16.0.3/32 dev %i
PostUp = ip route add 17.16.0.4/32 via 17.16.0.3 dev %i

PostDown = ip route del 17.16.0.1/32 dev %i
PostDown = ip route del 17.16.0.3/32 dev %i
PostDown = ip route del 17.16.0.4/32 via 17.16.0.3 dev %i
PostDown = firewall-cmd --zone=public --remove-port=51820/udp
PostDown = firewall-cmd --zone=public --remove-masquerade

[Peer]
PublicKey = <hope1_public_key>
AllowedIPs = 17.16.0.1/32

[Peer]
PublicKey = <hope3_public_key>
AllowedIPs = 17.16.0.0/24
Endpoint = <hope3_public_ip>:51820
PersistentKeepalive = 25
```
```bash
# /etc/wireguard/wg0.conf
[Interface]
Address = 17.16.0.3/24
PrivateKey = <hope3_private_key>
ListenPort = 51820

PreUp = sysctl -w net.ipv4.ip_forward=1
PreUp = firewall-cmd --zone=public --add-port=51820/udp
PreUp = firewall-cmd --zone=public --add-masquerade

PostUp = ip route add 17.16.0.1/32 via 17.16.0.2 dev %i
PostUp = ip route add 17.16.0.2/32 dev %i
PostUp = ip route add 17.16.0.4/32 dev %i

PostDown = ip route del 17.16.0.1/32 via 17.16.0.2 dev %i
PostDown = ip route del 17.16.0.2/32 dev %i
PostDown = ip route del 17.16.0.4/32 dev %i
PostDown = firewall-cmd --zone=public --remove-port=51820/udp
PostDown = firewall-cmd --zone=public --remove-masquerade

[Peer]
PublicKey = <hope2_public_key>
AllowedIPs = 17.16.0.1/32, 17.16.0.2/32
Endpoint = <hope2_public_ip>:51820
PersistentKeepalive = 25

[Peer]
PublicKey = <hope4_public_key>
AllowedIPs = 0.0.0.0/0
Endpoint = <hope4_public_ip>:51820
PersistentKeepalive = 25
```
```bash
# /etc/wireguard/wg0.conf
[Interface]
Address = 17.16.0.4/24
PrivateKey = <hope4_private_key>
ListenPort = 51820

PreUp = sysctl -w net.ipv4.ip_forward=1
PreUp = firewall-cmd --zone=public --add-port=51820/udp
PreUp = firewall-cmd --zone=public --add-masquerade
PreUp = firewall-cmd --direct --add-rule ipv4 nat POSTROUTING 0 -s 17.16.0.0/24 -o <internet_interface> -j MASQUERADE

PostUp = ip route add 17.16.0.0/24 dev %i

PostDown = ip route del 17.16.0.0/24 dev %i
PostDown = firewall-cmd --zone=public --remove-port=51820/udp
PostDown = firewall-cmd --zone=public --remove-masquerade
PostDown = firewall-cmd --direct --remove-rule ipv4 nat POSTROUTING 0 -s 17.16.0.0/24 -o <internet_interface> -j MASQUERADE

[Peer]
PublicKey = <hope3_public_key>
AllowedIPs = 17.16.0.0/24
Endpoint = <hope3_public_ip>:51820
PersistentKeepalive = 25
```
