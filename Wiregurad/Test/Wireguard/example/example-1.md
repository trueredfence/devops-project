
# Example 1
## User - HUB 1 - Gateway

### local settings for User
```ini
[Interface]
PrivateKey = mEQoZZjaxGle/cD+3kF2JOwnETkQ7XiZ9vD0l0bjjV4=
Address = 10.0.0.1/32
ListenPort = 443

# remote settings for Hope-1 
[Peer]
PublicKey = z8uQG6PsdDi2vTLrTcgQjcBGKwKS83hrfYJGL6skax0=
Endpoint = 84.252.95.249:443
AllowedIPs = 0.0.0.0/0
```

### local settings for Hope 1
```ini
[Interface]
PrivateKey = KEXXU9m3eLVDRl257lK7eWHCZNcvNPXivjT3868PWWo=
Address = 10.0.0.3/32
ListenPort = 443
Table = 123

# IPv4 forwarding & routing
PreUp = sysctl -w net.ipv4.ip_forward=1
PreUp = ip rule add iif wg0 table 123 priority 456
PostDown = ip rule del iif wg0 table 123 priority 456

# remote settings for User
[Peer]
PublicKey = CJjc/iBcCBX1B9dRhGUOT9677R+ZnTgnFtr1SxXplXE=
AllowedIPs = 10.0.0.1/32

# remote settings for Gateway
[Peer]
PublicKey = M+ltXLqYnnJ0PixvQh+9XEdpIIBfGR5crjCpVAJr60c=
AllowedIPs = 0.0.0.0/0
```
### local settings for Gateway
```ini
[Interface]
PrivateKey = YAJMggtIR8muV1++j+GlCvau+pnmmcZRRroQJjTe4UY=
Address = 10.0.0.2/32
ListenPort = 443
PreUp = sysctl -w net.ipv4.ip_forward=1
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE


# remote settings for Hope 1
[Peer]
PublicKey = z8uQG6PsdDi2vTLrTcgQjcBGKwKS83hrfYJGL6skax0=
Endpoint = 84.252.95.249:51823
AllowedIPs = 10.0.0.0/24
PersistentKeepalive = 25
```
