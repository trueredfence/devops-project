#!/bin/bash
set -e

# Bring up all WireGuard configurations
for config in /etc/wireguard/*.conf; do
  echo "Bringing up $config"
  wg-quick up "$config" || exit 1
done

# Keep the container running
tail -f /dev/null
