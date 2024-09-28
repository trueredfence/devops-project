# Wireguard Centos 7

## Install wiregurad in Cento 7

> [!IMPORTANT]
> As Centos7 comes to EOL we have to change Centos-Base.repo in centos7.
> [Centos7 Base Repo Link](../Centos7)

### Follow below step and reboot

```bash
yum update -y
yum install yum-utils -y
yum install epel-release elrepo-release -y
yum install kmod-wireguard wireguard-tools -y
--OR--
yum-config-manager --setopt=centosplus.includepkgs=kernel-plus --enablerepo=centosplus --save
sed -e 's/^DEFAULTKERNEL=kernel$/DEFAULTKERNEL=kernel-plus/' -i /etc/sysconfig/kernel
yum install kernel-plus wireguard-tools -y
reboot
```
```ini
additional
port open then
sudo firewall-cmd --zone=public --add-masquerade --permanent
sudo firewall-cmd --zone=public --remove-masquerade --permanent
firewall-cmd --zone=public --remove-masquerade

sudo ip route add 17.16.0.0/24 dev wg0
ip route del default via 17.16.0.0/24 dev wg0
```

### Firewall cmd for Hope

```bash
firewall-cmd --permanent --add-port=51820/udp && \
firewall-cmd --permanent --add-port=51821/udp && \
firewall-cmd --permanent --add-port=51822/udp && \
firewall-cmd --permanent --add-port=51823/udp && \
firewall-cmd --permanent --add-port=443/udp && \
firewall-cmd --reload
echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf
```

### Firewall Cmd for Exit point/ Gateway

```bash
# Add WireGuard port
firewall-cmd --permanent --add-port=51820/udp
firewall-cmd --zone=public --permanent --add-masquerade
systemctl reload firewalld
echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf
```

### Create conf file auto with bash

[Additional Link](https://www.wireguard.com/install/)

### Create pair of keys

```bash
# Manually
sudo mkdir -p /etc/wireguard/
cd /etc/wireguard
wg genkey | sudo tee /etc/wireguard/server_private.key | wg pubkey | sudo tee /etc/wireguard/server_public.key
```

### Script to create keypair for wireguard

```bash
#!/bin/bash

# Check if the number of key pairs to generate is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <number_of_key_pairs>"
    exit 1
fi
# Number of key pairs to generate
NUM_KEYS=$1

# Directory where the keys will be stored
KEY_DIR="."

# Generate the key pairs
for i in $(seq 1 $NUM_KEYS); do
    # Generate the private key
    wg genkey | sudo tee "${KEY_DIR}/private_${i}.key" | wg pubkey | sudo tee "${KEY_DIR}/public_${i}.key"
    echo "Generated key pair $i: private_${i}.key and public_${i}.key"
done

echo "All key pairs have been generated and saved in $KEY_DIR."
```

### Normal Client who want to connect to server

```ini
# /etc/wireguard/wg0.conf
[Interface]
Address = 10.10.10.1.x/24
PrivateKey = <Privatekey>
ListenPort = 51820
SaveConfig = true

[Peer]
PublicKey = <public key server>
AllowedIPs = 0.0.0.0/0
Endpoint = <next_hope_ip>:51820
PersistentKeepalive = 25

```

### Conf file Host A VPS `/etc/wireguard/wg0.conf`

```ini
# /etc/wireguard/wg0.conf
# Host A
[Interface]
Address = 10.10.10.1/24
SaveConfig = true
PrivateKey = <private key>
ListenPort = 51820
Table = 123

PreUp = sysctl -w net.ipv4.ip_forward=1
#PreUp = ip rule add iif wg0 table 123 priority 456
#PostDown = ip rule del iif wg0 table 123 priority 456

# Remote setting for 2nd hope
[Peer]
PublicKey = <next hope public key>
AllowedIPs = 0.0.0.0/0 # to allow untunneled traffic, use `0.0.0.0/1, 128.0.0.0/1` instead
Endpoint = <next-hope-ip>:51820
PersistentKeepalive = 25

```

### Host B Conf `/etc/wireguard/wg0.conf`

```ini
# /etc/wireguard/wg0.conf
# Host B
[Interface]
Address = 10.10.10.2/24
PrivateKey = <private key>
ListenPort = 51820
Table = 123

PreUp = sysctl -w net.ipv4.ip_forward=1
# PreUp = ip rule add iif wg0 table 123 priority 456
# PostDown = ip rule del iif wg0 table 123 priority 456

[Peer]
PublicKey = <previous-host-public-key>
AllowedIPs = <previous-host-ip>/32

# Remote setting for 3nd hope
[Peer]
PublicKey = <private key>
AllowedIPs = 0.0.0.0/0 # to allow untunneled traffic, use `0.0.0.0/1, 128.0.0.0/1` instead
Endpoint = <nex-hope-ip>:51820
PersistentKeepalive = 25

```

### Host C config or End point host where we have internet exit point `/etc/wireguard/wg0.conf`

```ini
# /etc/wireguard/wg0.conf
# Host -C
[Interface]
PrivateKey = 4N4EdSgB69soXBfsjHP/rgFPCdq5/NnUyXR3hdB21UU= # host c private key
Address = 10.10.10.3/24
ListenPort = 51820
#Table = 123
PreUp = sysctl -w net.ipv4.ip_forward=1
#PreUp = ip rule add iif wg0 table 123 priority 456
#PostDown = ip rule del iif wg0 table 123 priority 456

# Masquerade traffic for outgoing internet access
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

[Peer] # host -b PUblic key
PublicKey = <previous host private key>
AllowedIPs = <privious host ip>/32
# PersistentKeepalive = 25

```

```bash
#!/bin/bash
# ./createrole.sh client server server gateway
# Function to generate keys and save them
generate_keys() {
    private_key=$(wg genkey)
    public_key=$(echo $private_key | wg pubkey)
    echo $private_key > "$1_private.key"
    echo $public_key > "$1_public.key"
}

# Function to create client configuration
create_client_config() {
    private_key=$1
    peer_public_key=$2
    endpoint=$3
    config_file="client_${index}.conf"

    echo "[Interface]" > $config_file
    echo "Address = 10.10.10.${address_suffix}/24" >> $config_file
    echo "PrivateKey = $private_key" >> $config_file
    echo "DND = 1.1.1.1 8.8.8.8 9.9.9.9" >> $config_file
    echo "ListenPort = 51820" >> $config_file
    echo "SaveConfig = true" >> $config_file

    echo "[Peer]" >> $config_file
    echo "PublicKey = $peer_public_key" >> $config_file
    echo "AllowedIPs = 0.0.0.0/0" >> $config_file
    echo "Endpoint = $endpoint:51820" >> $config_file
    echo "PersistentKeepalive = 25" >> $config_file

    echo "Client configuration saved to $config_file"
}

# Function to create server configuration
create_server_config() {
    private_key=$1
    previous_peer_public_key=$2
    next_peer_public_key=$3
    next_peer_ip=$4
    config_file="server_${index}.conf"

    echo "[Interface]" > $config_file
    echo "Address = 10.10.10.${address_suffix}/24" >> $config_file
    echo "PrivateKey = $private_key" >> $config_file
    echo "ListenPort = 51820" >> $config_file
    echo "#Table = 123" >> $config_file

    echo "PreUp = sysctl -w net.ipv4.ip_forward=1" >> $config_file
    echo "#PreUp = ip rule add iif wg0 table 123 priority 456" >> $config_file
    echo "#PostDown = ip rule del iif wg0 table 123 priority 456" >> $config_file

    echo "[Peer]" >> $config_file
    echo "PublicKey = $previous_peer_public_key" >> $config_file
    echo "AllowedIPs = 10.10.10.${previous_suffix}/32" >> $config_file

    if [ -n "$next_peer_public_key" ]; then
        echo "[Peer]" >> $config_file
        echo "PublicKey = $next_peer_public_key" >> $config_file
        echo "AllowedIPs = 0.0.0.0/0" >> $config_file
        echo "Endpoint = $next_peer_ip:51820" >> $config_file
        echo "PersistentKeepalive = 25" >> $config_file
    fi

    echo "Server configuration saved to $config_file"
}

# Function to create gateway configuration
create_gateway_config() {
    private_key=$1
    previous_peer_public_key=$2
    config_file="gateway_${index}.conf"

    echo "[Interface]" > $config_file
    echo "Address = 10.10.10.${address_suffix}/24" >> $config_file
    echo "PrivateKey = $private_key" >> $config_file
    echo "ListenPort = 51820" >> $config_file

    echo "PreUp = sysctl -w net.ipv4.ip_forward=1" >> $config_file
    echo "PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE" >> $config_file
    echo "PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE" >> $config_file

    echo "[Peer]" >> $config_file
    echo "PublicKey = $previous_peer_public_key" >> $config_file
    echo "AllowedIPs = 10.10.10.${previous_suffix}/32" >> $config_file

    echo "Gateway configuration saved to $config_file"
}

# Validate arguments
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <role1> <role2> ... <roleN>"
    echo "Example: $0 client server gateway"
    exit 1
fi

# Initialize variables
index=1
address_suffix=1
previous_suffix=1
previous_private_key=""
previous_public_key=""
public_keys=()

# Create keys for each role
for role in "$@"; do
    generate_keys "role${index}"
    public_keys+=($(cat "role${index}_public.key"))
    index=$((index + 1))
done

# Reset index and address_suffix for configuration generation
index=1
address_suffix=1

# Create configurations based on roles
for role in "$@"; do
    private_key=$(cat "role${index}_private.key")
    public_key=$(cat "role${index}_public.key")

    case $role in
        "client")
            if [ $index -eq 1 ]; then
                next_peer_public_key=${public_keys[$index]}
                create_client_config $private_key $next_peer_public_key "<next-hop-ip>"
            else
                previous_peer_public_key=${public_keys[$((index - 2))]}
                create_client_config $private_key $previous_peer_public_key "<next-hop-ip>"
            fi
            ;;
        "server")
            previous_peer_public_key=${public_keys[$((index - 2))]}
            if [ $index -lt $# ]; then
                next_peer_public_key=${public_keys[$index]}
                next_peer_ip="<next-hop-ip>"
                create_server_config $private_key $previous_peer_public_key $next_peer_public_key $next_peer_ip
            else
                create_server_config $private_key $previous_peer_public_key "" ""
            fi
            ;;
        "gateway")
            previous_peer_public_key=${public_keys[$((index - 2))]}
            create_gateway_config $private_key $previous_peer_public_key
            ;;
        *)
            echo "Unknown role: $role"
            exit 1
            ;;
    esac

    previous_private_key=$private_key
    previous_public_key=$public_key
    previous_suffix=$address_suffix
    index=$((index + 1))
    address_suffix=$((address_suffix + 1))
done

# Clean up key files if needed
rm role*_private.key role*_public.key

echo "WireGuard configuration files created successfully."
```

### Command to handle wiregurad server

```bash
# Up wireguard network
wg-quick up /etc/wireguard/wg0.conf
# Down wireguard network
wg-quick down /etc/wireguard/wg0.conf
```

You Can Also use to start

```bash
systemctl start wg-quick@wg0.service
```

You Can Also use to stop

```bash
systemctl stop wg-quick@wg0.service
```

Enable auto-start at system boot time with the following command.

```bash
systemctl enable wg-quick@wg0.service
```
