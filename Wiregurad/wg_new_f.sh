#!/bin/bash

# Define color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Banner for script execution
echo -e "${BLUE}*************************************${NC}"
echo -e "${GREEN}         Start Gateway              ${NC}"
echo -e "${BLUE}*************************************${NC}"

# Global variables
RT_TABLE_PAYMENT="206 pmtroute"
LAN_PAYMENT="lan_pmt"
WAN_PAYMENT="wan_tun0"

# Function to handle errors
handle_error() {
    echo -e "${RED}$1 Exiting...${NC}"
    exit 1
}

clear_iptables() {
    echo "Flushing all iptables rules..."
    sudo iptables -F
    sudo iptables -t nat -F
    sudo iptables -t mangle -F

    echo "Deleting all user-defined chains..."
    sudo iptables -X
    sudo iptables -t nat -X
    sudo iptables -t mangle -X    
    echo "Iptables rules cleared successfully."
}

# Function to remove existing routes and rules
remove_route_and_rule() {
    local exit_interface="$1"
    local table_name="$2"

    if /sbin/ip route show table "$table_name" | grep -q "default via 172.16.0.1 dev $exit_interface"; then
        echo -e "${CYAN}Removing existing route...${NC}"
        /sbin/ip route del default via 172.16.0.1 dev "$exit_interface" table "$table_name" || handle_error "Failed to remove route."
    else
        echo -e "${GREEN}No existing route found. Skipping removal.${NC}"
    fi

    if /sbin/ip rule show table "$table_name" | grep -q "from 10.20.0.0/24"; then
        echo -e "${CYAN}Removing existing IP rule...${NC}"
        /sbin/ip rule del from 10.20.0.0/24 table "$table_name" || handle_error "Failed to remove routing rule."
    else
        echo -e "${GREEN}No existing IP rule found. Skipping removal.${NC}"
    fi
}

# Function to bring down all WireGuard interfaces
wg_interface_down() {
    local interfaces
    interfaces=$(wg show | awk '/interface/ {print $2}')

    if [[ -n $interfaces ]]; then
        for interface in $interfaces; do
            echo "Bringing down $interface..."
            wg-quick down "$interface" || handle_error "Failed to bring down interface $interface."
        done
    else
        echo "No WireGuard interfaces found. Doing nothing."
    fi
}

# Function to add a payment route
add_pay_route() {
    local lan_tun="$1"
    local wan_tun="$2"
    local rt_table="$3"
    local rt_table_name="${rt_table#* }"

    remove_route_and_rule "$wan_tun" "$rt_table_name"

    for intf in "$wan_tun" "$lan_tun"; do
        if ! wg show "$intf" > /dev/null 2>&1; then
            echo -e "${CYAN}Starting WireGuard interface $intf...${NC}"
            wg-quick up "$intf" || handle_error "Failed to bring up WireGuard interface $intf."
            echo -e "${GREEN}WireGuard interface $intf is up!${NC}"
        else
            echo -e "${GREEN}WireGuard interface $intf is already up. Ignoring...${NC}"
        fi
    done

    echo -e "${CYAN}Adding payment route...${NC}"

    if ! grep -q "$rt_table" /etc/iproute2/rt_tables; then
        echo -e "${YELLOW}Creating route table $rt_table...${NC}"
        echo "$rt_table" >> /etc/iproute2/rt_tables || handle_error "Failed to create route table."
    else
        echo -e "${GREEN}Route table $rt_table already exists. Ignoring...${NC}"
    fi

    echo -e "${CYAN}Configuring iptables for payment route...${NC}"
    iptables -t nat -A POSTROUTING -o "$wan_tun" -j MASQUERADE || handle_error "Failed to configure iptables."

    echo -e "${CYAN}Adding routing rules for payment route...${NC}"
    /sbin/ip rule add from 10.20.0.0/24 table "$rt_table_name" || handle_error "Failed to add routing rule."
    /sbin/ip route add default via 172.16.0.1 dev "$wan_tun" table "$rt_table_name" || handle_error "Failed to add route."

    echo -e "${GREEN}Tunnel route setup complete!${NC}"
}

# Main script execution based on arguments
case "$1" in
    start|restart)
        clear_iptables
        shorewall restart
        wg_interface_down
        add_pay_route "$LAN_PAYMENT" "$WAN_PAYMENT" "$RT_TABLE_PAYMENT"
        
        echo -e "${GREEN}Gateway $1 successfully!${NC}"
        ;;
    stop)        
        wg_interface_down
        remove_route_and_rule "$WAN_PAYMENT" "${RT_TABLE_PAYMENT#* }"
        clear_iptables
        shorewall restart
        echo -e "${GREEN}Gateway stopped successfully!${NC}"
        ;;
    *)
        echo -e "${RED}Usage: $0 {start|restart|stop}${NC}"
        exit 1
        ;;
esac
