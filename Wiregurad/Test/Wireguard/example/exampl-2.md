# Example 1

## User - HUB 1 - Gateway

### local settings for User

```ini
[Interface]
PrivateKey = iFQnqrZaTzYvJH2y3D0qnSeu8zF1IXCS2i7iZ8rCnmw=
Address = 172.16.0.1/32
ListenPort = 443
DNS = 1.1.1.1 8.8.8.8 9.9.9.9
# remote settings for Hope-1
[Peer]
PublicKey = syVv7Xmrqj9L6ZhCeCscnMcYFHIwmik5GFY3OnmfSCM=
Endpoint = 192.168.56.120:443
AllowedIPs = 0.0.0.0/0
```

### local settings for Hub 1

```ini
# local settings for Hub 1
[Interface]
PrivateKey = uIt4Ez3ffioQF2coK9kRZIVlWG40vH2alOtE/QzyrUY=
Address = 172.16.0.2/32
ListenPort = 443

PreUp = sysctl -w net.ipv4.ip_forward=1

# remote settings for Endpoint A
[Peer]
PublicKey = wo1/DfV7pji49ZxuKqdjpwiXaCmpM68O+JYtKbIgjwU=
AllowedIPs = 172.16.0.1/32

# remote settings for Hub 2
[Peer]
PublicKey = Ah5no4vX/ALbHX1wlIUeKvWUCXU9ycheSq2wwo+sWTc=
Endpoint = 84.252.95.249:443
AllowedIPs = 172.16.0.0/24
```

### local settings for Hub2

```ini
[Interface]
PrivateKey = OEx1djc3ATO44h6zrFBSznMseXzjBGaLclTn98HeVUc=
Address = 172.16.0.3/32
ListenPort = 443

PreUp = sysctl -w net.ipv4.ip_forward=1

# remote settings for Hope1
[Peer]
PublicKey = syVv7Xmrqj9L6ZhCeCscnMcYFHIwmik5GFY3OnmfSCM=
#Endpoint = 198.51.100.10:51823
AllowedIPs = 172.16.0.2/32

# remote settings for hope3/Gateway
[Peer]
PublicKey = Dtd9CK+uJUoW0o66AxEM2ySWjUkec1JCXvYccqi4rD0=
Endpoint = 178.63.172.28:443
AllowedIPs = 172.16.0.0/24
```

### local settings for Gateway

```ini
[Interface]
PrivateKey = kFa3XmMnB1SL18/e0WNepf8n9fLsiGJOZJrTHEA/SVE=
Address = 172.16.0.4/32
ListenPort = 443
PreUp = sysctl -w net.ipv4.ip_forward=1
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE


# remote settings for Hope 1
[Peer]
PublicKey = Ah5no4vX/ALbHX1wlIUeKvWUCXU9ycheSq2wwo+sWTc=
Endpoint = 84.252.95.249:443
AllowedIPs = 172.16.0.0/24
PersistentKeepalive = 25
```
