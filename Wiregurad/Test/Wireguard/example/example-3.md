# Example-3 Working 
### Gateway with Net, hope1 and hope2
```ini
[Interface]
Address = 172.16.0.1/24
PrivateKey = OMPlkeLzcAEEYvOR72rbKjvRjdVWqaXylguPHux7PUY=
DNS = 1.1.1.1 8.8.8.8 9.9.9.9
ListenPort = 51820
SaveConfig = true
[Peer]
PublicKey = 2pTmCw6lEQqnypkCzP56jockfTInrhhW8+AZKJ6CjXQ=
AllowedIPs = 0.0.0.0/0
Endpoint = 188.208.141.186:443
PersistentKeepalive = 25
```

```ini
[Interface]
Address = 172.16.0.2/24
PrivateKey = AAbfEP6jZK0BkodEdfXumnhFkOD844b97HEj9PX9kGI=
ListenPort = 443
Table = 123
PreUp = sysctl -w net.ipv4.ip_forward=1
PreUp = ip rule add iif wg0 table 123 priority 456
PostDown = ip rule del iif wg0 table 123 priority 456

[Peer]
PublicKey = BKUOPfgZRXDbH2moKRQ5hOP9omGaFBVk0+FUB3db4Tk=
AllowedIPs = 172.16.0.1/32

[Peer]
PublicKey = QiWuUeoIN9+zvTL0bVzLGWLRJ0BlpHMOARo3L39620k=
AllowedIPs = 0.0.0.0/0
#AllowedIPs = 172.16.0.0/24

Endpoint = 178.63.172.28:443
PersistentKeepalive = 25
```
```ini
[Interface]
Address = 172.16.0.3/24
PrivateKey = iCuiezW6lSvlqB/fTOV++A9qN4hAJVIbrmYDhEwATE0=
ListenPort = 443
PreUp = sysctl -w net.ipv4.ip_forward=1
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
[Peer]
PublicKey = 2pTmCw6lEQqnypkCzP56jockfTInrhhW8+AZKJ6CjXQ=
AllowedIPs = 172.16.0.2/32
```
