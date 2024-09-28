# Multi-Hop WireGuard Tunnel Configuration

This guide provides the configuration details and necessary commands to set up a multi-hop WireGuard tunnel across four CentOS 7 hosts (HostA -> HostB -> HostC -> HostD) where HostA uses HostD's internet connection.

## HostA Configuration

### `/etc/wireguard/wg0.conf` for HostA, C
```ini
[Interface]
PrivateKey = <HostA_Private_Key>
Address = 10.0.0.1/24

[Peer]
PublicKey = <HostB_Public_Key>
Endpoint = <HostB_IP>:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25

# Enable IP forwarding
PreUp = sysctl -w net.ipv4.ip_forward=1
# Routing rule for wg0
PreUp = ip rule add iif wg0 table 123 priority 456
PostDown = ip rule del iif wg0 table 123 priority 456
```

### firewall Cmds for HostA,B,C
```bash
# Add WireGuard port
firewall-cmd --permanent --add-port=51820/udp

# Ensure SSH traffic uses the main routing table
ip rule add from <your_client_ip> to <HostA_IP> table main priority 100

# Reload firewalld
firewall-cmd --reload

```
### Host B conf file

```ini
[Interface]
PrivateKey = <HostB_Private_Key>
Address = 10.0.1.1/24

[Peer]
PublicKey = <HostA_Public_Key>
AllowedIPs = 10.0.0.0/24
PersistentKeepalive = 25

[Peer]
PublicKey = <HostC_Public_Key>
Endpoint = <HostC_IP>:51820
AllowedIPs = 0.0.0.0/0

PreUp = sysctl -w net.ipv4.ip_forward=1
PreUp = ip rule add iif wg0 table 123 priority 456
PostDown = ip rule del iif wg0 table 123 priority 456

```

### `/etc/wireguard/wg0.conf` for HostD
```ini
[Interface]
PrivateKey = <HostD_Private_Key>
Address = 10.0.3.1/24

[Peer]
PublicKey = <HostC_Public_Key>
AllowedIPs = 10.0.2.0/24
PersistentKeepalive = 25

PreUp = sysctl -w net.ipv4.ip_forward=1
PreUp = ip rule add iif wg0 table 123 priority 456
PostDown = ip rule del iif wg0 table 123 priority 456

# Masquerade traffic for outgoing internet access
PostUp = iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
```
### firewall Cmds for HostD
```bash
# Add WireGuard port
firewall-cmd --permanent --add-port=51820/udp

# Exclude SSH traffic from masquerading
iptables -t nat -A POSTROUTING -p tcp --dport 22 -j ACCEPT

# Apply masquerading for other traffic
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Ensure SSH traffic uses the main routing table
ip rule add from <your_client_ip> to <HostD_IP> table main priority 100

# Reload firewalld
firewall-cmd --reload

```
yum install wireguard-dkms wireguard-tools qrencode
