# Config sample Wireguard

## Config file sample on gw where this config file will filter traffic based on give conditions below

### Firewall commanda to route traffic from wg0 to tun1 and filter traffic on wg0 before route to tun1

```bash
# Allow new connections from wg0 to wg1
iptables -A FORWARD -i wg0 -o tun1 -m state --state NEW -j ACCEPT

# Allow established and related connections (from tun1 to wg0 and back)
iptables -A FORWARD -i tun1 -o wg0 -m state --state ESTABLISHED,RELATED -j ACCEPT

# (Optional) Log dropped packets for validation/monitoring
iptables -A FORWARD -i wg0 -o tun1 -m state --state INVALID -j LOG --log-prefix "INVALID WG0->tun1: "

# Drop invalid packets (security)
iptables -A FORWARD -i wg0 -o tun1 -m state --state INVALID -j DROP


# Masquerade traffic from wg0 going to wg1
iptables -t nat -A POSTROUTING -o tun1 -s 172.17.11.0/24 -j MASQUERADE && \
iptables -t nat -A POSTROUTING -o wg0 -s 172.16.10.0/24 -j MASQUERADE


# Masquerade traffic from wg1 going to wg0
```

```ini
# Direct connection Server File
[Interface]
Address = 172.16.10.1/24
PrivateKey = 6EnUmNFMJIZ5svYUuZ3LWMmv4sLLf3Ylhk3cne371Uc=
ListenPort = 443

# Working ok not filter
PreUp = sysctl -w net.ipv4.ip_forward=1
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o enp0s3 -j MASQUERADE; iptables -A FORWARD -i tun1 -o wg0 -m state --state RELATED,ESTABLISHED -j ACCEPT
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o enp0s3 -j MASQUERADE; iptables -D FORWARD -i tun1 -o wg0 -m state --state RELATED,ESTABLISHED -j ACCEPT


# Allow all deny selected working fine
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o tun1 -j MASQUERADE; iptables -A FORWARD -i tun1 -o wg0 -m state --state RELATED,ESTABLISHED -j ACCEPT; iptables -I FORWARD -i wg0 -o tun1 -p tcp --dport 8080 -j DROP
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o tun1 -j MASQUERADE; iptables -D FORWARD -i tun1 -o wg0 -m state --state RELATED,ESTABLISHED -j ACCEPT; iptables -D FORWARD -i wg0 -o tun1 -p tcp --dport 8080 -j DROP


# Deny All allow only specific port in ip table #DSN Resolve ISSUE

PostUp = iptables -I FORWARD 1 -i wg0 -o tun1 -p tcp --dport 443 -j ACCEPT; iptables -I FORWARD 1 -i wg0 -o tun1 -p tcp --dport 80 -j ACCEPT; iptables -I FORWARD 1 -i wg0 -o tun1 -p tcp --dport 53 -j ACCEPT;iptables -I FORWARD 2 -i wg0 -o tun1 -j DROP; iptables -t nat -A POSTROUTING -o tun1 -j MASQUERADE; iptables -A FORWARD -i tun1 -o wg0 -m state --state RELATED,ESTABLISHED -j ACCEPT
PostDown = iptables -D FORWARD -i wg0 -o tun1 -p tcp --dport 443 -j ACCEPT; iptables -D FORWARD 1 -i wg0 -o tun1 -p tcp --dport 80 -j ACCEPT; iptables -I FORWARD 1 -i wg0 -o tun1 -p tcp --dport 53 -j ACCEPT; iptables -D FORWARD -i wg0 -o tun1 -j DROP; iptables -t nat -D POSTROUTING -o tun1 -j MASQUERADE; iptables -D FORWARD -i tun1 -o wg0 -m state --state RELATED,ESTABLISHED -j ACCEPT


# DNS Resolved with UDP and TCP Prototcal
PostUp = iptables -I FORWARD 1 -i wg0 -o tun1 -p udp --dport 53 -j ACCEPT; iptables -I FORWARD 2 -i wg0 -o tun1 -p tcp --dport 53 -j ACCEPT; iptables -I FORWARD 3 -i wg0 -o tun1 -p tcp --dport 443 -j ACCEPT; iptables -I FORWARD 4 -i wg0 -o tun1 -j DROP; iptables -t nat -A POSTROUTING -o tun1 -j MASQUERADE; iptables -A FORWARD -i tun1 -o wg0 -m state --state RELATED,ESTABLISHED -j ACCEPT
PostDown = iptables -D FORWARD -i wg0 -o tun1 -p udp --dport 53 -j ACCEPT; iptables -D FORWARD -i wg0 -o tun1 -p tcp --dport 53 -j ACCEPT; iptables -D FORWARD -i wg0 -o tun1 -p tcp --dport 443 -j ACCEPT; iptables -D FORWARD -i wg0 -o tun1 -j DROP; iptables -t nat -D POSTROUTING -o tun1 -j MASQUERADE; iptables -D FORWARD -i tun1 -o wg0 -m state --state RELATED,ESTABLISHED -j ACCEPT
```

## Exit node (tun1) of gateway

```ini
# Direct connection Server File
[Interface]
Address = 172.16.11.1/24
PrivateKey = EHNeqUhdy/NBEqNput3UwPnxGK5WjAyHpfsyk6M/r1E=
ListenPort = 444

Table = 124
PreUp = sysctl -w net.ipv4.ip_forward=1
PreUp = ip rule add iif wg1 table 124 priority 456
PostDown = ip rule del iif wg1 table 124 priority 456

[Peer]
PublicKey = 0URdsOoU0aPu6RNV+lB6bFi/ZhaIqxw+Tg6ChVFCN3A=
AllowedIPs = 172.16.11.101/32

#Tun0 Public key
[Peer]
PublicKey = PDRc05gzUYDSzfs+VFVHdKRAPAa1GZdQNfkqPtYOMVk=
AllowedIPs = 172.17.11.0/24
```

### Exit Node

```ini
# Direct connection Server File
[Interface]
Address = 172.17.11.3/24
PrivateKey = sFf2kfaEitzvKjISf9SJpW2K4K61AP2eWgntojPob08=
ListenPort = 443

PreUp = sysctl -w net.ipv4.ip_forward=1
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o enp0s3 -j MASQUERADE
wqPostiDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o enp0s3 -j MASQUERADE

#GE
[Peer]
PublicKey = qZl/6jSRm45mfA7c4kQkCSoNS4VdQCqwxGBOCLKlPxE=
AllowedIPs = 172.17.11.2/32
```
