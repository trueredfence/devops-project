#!/bin/bash

# Check if the correct number of arguments is passed
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <number-of-clients> <endpoint-ip>"
    exit 1
fi

NUM_CLIENTS=$1
ENDPOINT_IP=$2
START_IP="172.16.11.101"
WG_PORT=51820

# Create the directory for configs if it doesn't exist
mkdir -p wg_configs

# Generate the host's private and public keys
HOST_PRIVATE_KEY=$(wg genkey)
HOST_PUBLIC_KEY=$(echo "$HOST_PRIVATE_KEY" | wg pubkey)

# Create the host.conf file
echo "" > wg_configs/host.conf  # Make sure the file starts empty

# Loop through and create client configurations
for ((i=0; i<$NUM_CLIENTS; i++))
do
    CLIENT_NUM=$(($i + 1))
    CLIENT_IP="172.16.11.$(($i + 101))"
    
    # Generate keys for each client
    CLIENT_PRIVATE_KEY=$(wg genkey)
    CLIENT_PUBLIC_KEY=$(echo "$CLIENT_PRIVATE_KEY" | wg pubkey)
    
    # Create client configuration
    CLIENT_CONF="wg_configs/client_${CLIENT_NUM}.conf"
    echo "[Interface]" > $CLIENT_CONF
    echo "PrivateKey = $CLIENT_PRIVATE_KEY" >> $CLIENT_CONF
    echo "Address = $CLIENT_IP/24" >> $CLIENT_CONF
    echo "" >> $CLIENT_CONF

    echo "[Peer]" >> $CLIENT_CONF
    echo "PublicKey = $HOST_PUBLIC_KEY" >> $CLIENT_CONF
    echo "Endpoint = $ENDPOINT_IP:$WG_PORT" >> $CLIENT_CONF
    echo "AllowedIPs = 0.0.0.0/0" >> $CLIENT_CONF
    echo "PersistentKeepalive = 25" >> $CLIENT_CONF
    
    # Append peer configuration to host.conf
    echo "[Peer]" >> wg_configs/host.conf
    echo "PublicKey = $CLIENT_PUBLIC_KEY" >> wg_configs/host.conf
    echo "AllowedIPs = $CLIENT_IP/32" >> wg_configs/host.conf
    echo "" >> wg_configs/host.conf
done

echo "WireGuard configuration for $NUM_CLIENTS clients generated!"
