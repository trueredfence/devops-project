#!/bin/bash
# ./createrole.sh client server server gateway
# Function to generate keys and save them
generate_keys() {
    private_key=$(wg genkey)
    public_key=$(echo $private_key | wg pubkey)
    echo $private_key > "$ROLES_DIR/$1_private.key"
    echo $public_key > "$ROLES_DIR/$1_public.key"
}

# Function to create client configuration
create_client_config() {
    private_key=$1
    peer_public_key=$2
    endpoint=$3
    config_file="$ROLES_DIR/client_${index}.conf"

    echo "[Interface]" > $config_file
    echo "Address = 172.16.0.${address_suffix}/24" >> $config_file
    echo "PrivateKey = $private_key" >> $config_file
    echo "DNS = 1.1.1.1 8.8.8.8 9.9.9.9" >> $config_file
    echo "ListenPort = 51820" >> $config_file
    echo "SaveConfig = true" >> $config_file

    echo "[Peer]" >> $config_file
    echo "#Name# = Client"
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
    config_file="$ROLES_DIR/hope_${index}.conf"

    echo "[Interface]" > $config_file
    echo "#Name# = Hope"
    echo "Address = 172.16.0.${address_suffix}/24" >> $config_file
    echo "PrivateKey = $private_key" >> $config_file
    echo "ListenPort = 443" >> $config_file
    echo "Table = 123" >> $config_file

    echo "PreUp = sysctl -w net.ipv4.ip_forward=1" >> $config_file
    echo "PreUp = ip rule add iif wg0 table 123 priority 456" >> $config_file
    echo "PostDown = ip rule del iif wg0 table 123 priority 456" >> $config_file

    echo "[Peer]" >> $config_file
    echo "#Name# = Client"
    echo "PublicKey = $previous_peer_public_key" >> $config_file
    echo "AllowedIPs = 172.16.0.${previous_suffix}/32" >> $config_file

    if [ -n "$next_peer_public_key" ]; then
        echo "[Peer]" >> $config_file
        echo "#Name# = Remote"
        echo "PublicKey = $next_peer_public_key" >> $config_file
        echo "AllowedIPs = 0.0.0.0/0" >> $config_file
        echo "Endpoint = $next_peer_ip:443" >> $config_file
        echo "PersistentKeepalive = 25" >> $config_file
    fi

    echo "Server configuration saved to $config_file"
}

# Function to create gateway configuration
create_gateway_config() {
    private_key=$1
    previous_peer_public_key=$2
    config_file="$ROLES_DIR/gateway_${index}.conf"

    echo "[Interface]" > $config_file
    echo "#Name# = GW"
    echo "Address = 172.16.0.${address_suffix}/24" >> $config_file
    echo "PrivateKey = $private_key" >> $config_file
    echo "ListenPort = 443" >> $config_file

    echo "PreUp = sysctl -w net.ipv4.ip_forward=1" >> $config_file
    echo "PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE" >> $config_file
    echo "PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE" >> $config_file

    echo "[Peer]" >> $config_file
    echo "#Name# = Level"
    echo "PublicKey = $previous_peer_public_key" >> $config_file
    echo "AllowedIPs = 172.16.0.${previous_suffix}/32" >> $config_file

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
ROLES_DIR="roles"
public_keys=()

# Create keys for each role
for role in "$@"; do
    generate_keys "${role}${index}"
    public_keys+=($(cat "$ROLES_DIR/${role}${index}_public.key"))
    index=$((index + 1))
done

# Reset index and address_suffix for configuration generation
index=1
address_suffix=1
mkdir -p "$ROLES_DIR"
# Create configurations based on roles
for role in "$@"; do
    private_key=$(cat "$ROLES_DIR/${role}${index}_private.key")
    public_key=$(cat "$ROLES_DIR/${role}${index}_public.key")

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
        "hope")
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
# rm role*_private.key role*_public.key

echo "WireGuard configuration files created successfully."