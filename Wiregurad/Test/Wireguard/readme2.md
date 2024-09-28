```ini
# /etc/wireguard/wg0.conf
[Interface]
Address = 17.16.0.1/24
PrivateKey = <hope1_private_key>
ListenPort = 51820

[Peer]
PublicKey = <hope2_public_key>
AllowedIPs = 17.16.0.0/24
Endpoint = <hope2_public_ip>:51820
PersistentKeepalive = 25
```
```bash
# Enable IP forwarding
echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Set up routing
sudo ip route add 17.16.0.0/24 dev wg0
sudo ip route add default via 17.16.0.2 dev wg0

# Configure firewalld
sudo firewall-cmd --zone=public --add-port=51820/udp --permanent
sudo firewall-cmd --zone=public --add-masquerade --permanent
sudo firewall-cmd --reload
```

```ini
# /etc/wireguard/wg0.conf
[Interface]
Address = 17.16.0.2/24
PrivateKey = <hope2_private_key>
ListenPort = 51820

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
# Enable IP forwarding
echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Set up routing
sudo ip route add 17.16.0.1/32 dev wg0
sudo ip route add 17.16.0.3/32 dev wg0
sudo ip route add 17.16.0.4/32 via 17.16.0.3 dev wg0

# Configure firewalld
sudo firewall-cmd --zone=public --add-port=51820/udp --permanent
sudo firewall-cmd --zone=public --add-masquerade --permanent
sudo firewall-cmd --reload
```
```ini
# /etc/wireguard/wg0.conf
[Interface]
Address = 17.16.0.3/24
PrivateKey = <hope3_private_key>
ListenPort = 51820

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
# Enable IP forwarding
echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Set up routing
sudo ip route add 17.16.0.1/32 via 17.16.0.2 dev wg0
sudo ip route add 17.16.0.2/32 dev wg0
sudo ip route add 17.16.0.4/32 dev wg0

# Configure firewalld
sudo firewall-cmd --zone=public --add-port=51820/udp --permanent
sudo firewall-cmd --zone=public --add-masquerade --permanent
sudo firewall-cmd --reload
```
```ini
# /etc/wireguard/wg0.conf
[Interface]
Address = 17.16.0.4/24
PrivateKey = <hope4_private_key>
ListenPort = 51820

[Peer]
PublicKey = <hope3_public_key>
AllowedIPs = 17.16.0.0/24
Endpoint = <hope3_public_ip>:51820
PersistentKeepalive = 25
```
```bash
# Enable IP forwarding
echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Set up routing
sudo ip route add 17.16.0.0/24 dev wg0

# Configure firewalld
sudo firewall-cmd --zone=public --add-port=51820/udp --permanent
sudo firewall-cmd --zone=public --add-masquerade --permanent
sudo firewall-cmd --reload

# Enable NAT for WireGuard traffic
sudo firewall-cmd --direct --add-rule ipv4 nat POSTROUTING 0 -s 17.16.0.0/24 -o <internet_interface> -j MASQUERADE
sudo firewall-cmd --reload
```
