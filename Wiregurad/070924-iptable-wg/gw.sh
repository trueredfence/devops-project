#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Banner
echo -e "${CYAN}========================================${NC}"
echo -e "${MAGENTA}      Setting up Gateway V 1.0          ${NC}"
echo -e "${CYAN}========================================${NC}"

## Custom Variables
declare -A zones=(

    ["lan-zone"]="lan-t1 lan-t2"
    ["wan-zone"]="wan-t1 wan-t2"
)

declare -a laninterface=("enp0s8" "enp0s10")

declare -A lantun=(
    ["lan-t1"]="443/tcp,80/tcp"
)

declare -a waninterface=("enp0s3" "enp0s9")
declare -a wantun=("wan-t1")
declare -a directtun=("lan-direct")

showmsg() {
    if [ "$1" == "info" ]; then
        echo -e "${YELLOW}$2${NC}"
    elif [ "$1" == "error" ]; then
        echo -e "${RED}$2${NC}"
    else
        echo -e "${BLUE}$1${NC}"
    fi
}

# Check if the entry exists
ENTRY="net.ipv4.ip_forward = 1"
FILE="/etc/sysctl.conf"
showmsg info "Checking if ip forward is set to 1..."
if grep -q "^${ENTRY}" "$FILE"; then
    showmsg "ip forward value already set to 1"
else
    # Add the entry
    echo "${ENTRY}" | sudo tee -a "$FILE" > /dev/null
    sudo sysctl -w net.ipv4.ip_forward=1
    showmsg "sysctl configuration updated"
fi
showmsg info "Configuring firewalld service for Gateway..."

lan_zone() {
    showmsg info "Adding masquerade rule..."
    sudo firewall-cmd --permanent --add-masquerade
    if [ $? -eq 0 ]; then
        showmsg "Masquerade rule added successfully."
    else
        showmsg error "Failed to add masquerade rule"
    fi

    # Add forward rule
    showmsg info "Adding forward rule..."
    sudo firewall-cmd --permanent --add-forward
    if [ $? -eq 0 ]; then
        showmsg "Forward rule added successfully."
    else
        showmsg error "Failed to add forward rule."
    fi

    # Allow ICMP protocol
    showmsg info "Allowing ICMP protocol..."
    sudo firewall-cmd --permanent --add-protocol=icmp
    if [ $? -eq 0 ]; then
        showmsg "ICMP protocol allowed."
    else
        showmsg error "Failed to allow ICMP protocol."
    fi

    # Allow UDP port 51820
    showmsg info "Allowing UDP port 51820..."
    sudo firewall-cmd --permanent --add-port=51820/udp
    if [ $? -eq 0 ]; then
        showmsg "UDP port 51820 allowed."
    else
        showmsg error "Failed to allow UDP port 51820."
    fi

    # Allow UDP port 51821
    showmsg info "Allowing UDP port 51821..."
    sudo firewall-cmd --permanent --add-port=51821/udp
    if [ $? -eq 0 ]; then
        showmsg "UDP port 51821 allowed."
    else
        showmsg error "Failed to allow UDP port 51821."
    fi

    # Allow HTTP service
    showmsg info "Allowing HTTP service..."
    sudo firewall-cmd --permanent --add-service=http
    if [ $? -eq 0 ]; then
        showmsg "HTTP service allowed."
    else
        showmsg error "Failed to allow HTTP service."
    fi

    # Allow HTTPS service
    showmsg info "Allowing HTTPS service..."
    sudo firewall-cmd --permanent --add-service=https
    if [ $? -eq 0 ]; then
        showmsg "HTTPS service allowed."
    else
        showmsg error "Failed to allow HTTPS service."
    fi

    # Reload firewall to apply changes
    showmsg info "Reloading firewall..."
    sudo firewall-cmd --reload
    if [ $? -eq 0 ]; then
        showmsg "Firewall reloaded successfully."
    else
        showmsg error "Failed to reload firewall."
    fi

    # End of script
    showmsg info "Firewall configuration for public zone complete!"
}

# Function to create a new zone and configure it
create_zone() {
    for zone in "${!zones[@]}"; do
        # Create a new zone
        showmsg info "Creating new zone: $zone..."
        sudo firewall-cmd --permanent --new-zone=$zone
        if [ $? -eq 0 ]; then
            showmsg "Zone $zone created successfully."
        else
            showmsg error "Failed to create zone $zone."
            return 1
        fi

        showmsg info "Adding masquerade to zone $zone..."
        sudo firewall-cmd --permanent --zone=$zone --add-masquerade
        if [ $? -eq 0 ]; then
            showmsg "Masquerade added to zone $zone."
        else
            showmsg error "Failed to add masquerade to zone $zone."
            return 1
        fi

        # Set the target for the zone
        showmsg info "Setting target to ACCEPT for zone $zone..."
        sudo firewall-cmd --permanent --zone=$zone --set-target=ACCEPT
        if [ $? -eq 0 ]; then
            showmsg "Target set to ACCEPT for zone $zone."
        else
            showmsg error "Failed to set target to ACCEPT for zone $zone."
            return 1
        fi

        # Enable forwarding for the zone
        showmsg info "Enabling forwarding for zone $zone..."
        sudo firewall-cmd --permanent --zone=$zone --add-forward
        if [ $? -eq 0 ]; then
            showmsg "Forwarding enabled for zone $zone."
        else
            showmsg error "Failed to enable forwarding for zone $zone."
            return 1
        fi

        for interface in ${zones[$zone]}; do
            showmsg info "Adding interface $interface to zone $zone..."
            sudo firewall-cmd --permanent --zone=$zone --add-interface=$interface
            if [ $? -eq 0 ]; then
                showmsg "Interface $interface added to zone $zone."
            else
                showmsg error "Failed to add interface $interface to zone $zone."
                return 1
            fi
        done

        # Reload the firewall to apply changes
        showmsg info "Reloading firewall to apply changes..."
        sudo firewall-cmd --reload
        if [ $? -eq 0 ]; then
            showmsg "Firewall reloaded successfully."
        else
            showmsg error "Failed to reload firewall."
            return 1
        fi
    done
}



# Function to create and configure the drop_tun policy
create_policy() {
    local policy="drop_tun"

    # Create the new policy
    showmsg info "Creating new policy: $policy..."
    sudo firewall-cmd --permanent --new-policy=$policy
    if [ $? -eq 0 ]; then
        showmsg "Policy $policy created successfully."
    else
        showmsg error "Failed to create policy $policy."
        return 1
    fi
    
    # Add ingress zones (lan-t1, lan-t2, etc.) to the policy
    for zone in "${!zones[@]}"; do
       if [[ $zone == lan-* ]]; then
            showmsg info "Adding ingress zone $zone to policy $policy..."
            sudo firewall-cmd --permanent --policy=$policy --add-ingress-zone=$zone
            if [ $? -eq 0 ]; then
                showmsg "Ingress zone $zone added to policy $policy."
            else
                showmsg error "Failed to add ingress zone $zone to policy $policy."
                return 1
            fi
        fi
    done
    
    # Add egress zone to the policy (public zone)
    showmsg info "Adding egress zone 'public' to policy $policy..."
    sudo firewall-cmd --permanent --policy=$policy --add-egress-zone=public
    if [ $? -eq 0 ]; then
        showmsg "Egress zone 'public' added to policy $policy."
    else
        showmsg error "Failed to add egress zone 'public' to policy $policy."
        return 1
    fi

    # Set the target to DROP for the policy
    showmsg info "Setting target to DROP for policy $policy..."
    sudo firewall-cmd --permanent --policy=$policy --set-target=DROP
    if [ $? -eq 0 ]; then
        showmsg "Target set to DROP for policy $policy."
    else
        showmsg error "Failed to set target to DROP for policy $policy."
        return 1
    fi

    # Reload the firewall to apply changes
    showmsg info "Reloading firewall to apply changes..."
    sudo firewall-cmd --reload
    if [ $? -eq 0 ]; then
        showmsg "Firewall reloaded successfully."
    else
        showmsg error "Failed to reload firewall."
    fi
}

bring_up_tunnels() {
    
    # Loop through each tunnel in the wantun array and bring it up
    for tunnel in "${wantun[@]}"; do
        showmsg info "Bringing up WireGuard tunnel: $tunnel..."
        sudo wg-quick up "$tunnel"
        if [ $? -eq 0 ]; then
            showmsg "$tunnel tunnel brought up successfully."
        else
            showmsg error "Failed to bring up $tunnel tunnel."
        fi
    done
     # Loop through each tunnel in the wantun array and bring it up
    for tunnel in "${!lantun[@]}"; do
        showmsg info "Bringing up WireGuard tunnel: $tunnel..."
        sudo wg-quick up "$tunnel"
        if [ $? -eq 0 ]; then
            showmsg "$tunnel tunnel brought up successfully."
        else
            showmsg error "Failed to bring up $tunnel tunnel."
        fi
    done
}

bring_down_tunnels() {
    
    # Loop through each tunnel in the wantun array and bring it up
    for tunnel in "${wantun[@]}"; do
        showmsg info "Bringing down WireGuard tunnel: $tunnel..."
        sudo wg-quick down "$tunnel"
        if [ $? -eq 0 ]; then
            showmsg "$tunnel tunnel brought down successfully."
        else
            showmsg error "Failed to bring down $tunnel tunnel."
        fi
    done
     # Loop through each tunnel in the wantun array and bring it up
    for tunnel in "${!lantun[@]}"; do
        showmsg info "Bringing down WireGuard tunnel: $tunnel..."
        sudo wg-quick down "$tunnel"
        if [ $? -eq 0 ]; then
            showmsg "$tunnel tunnel brought down successfully."
        else
            showmsg error "Failed to bring down $tunnel tunnel."
        fi
    done
}

# Function to fetch the IP address of the corresponding WAN interface
get_wan_ip() {
    local wan_interface=$1
    
    
    # Get the IP address of the corresponding WAN interface
    local ip=$(ip addr show "$wan_interface" | grep "inet " | awk '{print $2}' | cut -d/ -f1)
    echo "$ip"
}

# Function to add rules and routes for each interface in lantun array
configure_routing() {
    
    local priority=206
    local table=123

    # Loop through each interface in the lantun array
    for lan_interface in "${!lantun[@]}"; do
        showmsg info "Configuring routing for interface: $lan_interface with priority $priority..."
        wan_interface="${lan_interface/lan/wan}"
        # Fetch the corresponding WAN IP
        wan_ip=$(get_wan_ip "$wan_interface")
        
        if [ -z "$wan_ip" ]; then
            showmsg error "Failed to fetch WAN IP for $lan_interface. Skipping this interface."
            continue
        fi

        # Add the ip rule if it doesn't already exist
        showmsg info "Checking if ip rule exists: iif $lan_interface table $table priority $priority"
        if ! ip rule show | grep -q "iif $lan_interface lookup $table"; then
            showmsg info "Adding ip rule: iif $lan_interface table $table priority $priority"
            sudo ip rule add iif "$lan_interface" table "$table" priority "$priority"
            if [ $? -eq 0 ]; then
                showmsg "ip rule added for $lan_interface."
            else
                showmsg error "Failed to add ip rule for $lan_interface."
                continue
            fi
        else
            showmsg info "ip rule for $lan_interface already exists. Skipping."
        fi

        # Add the route for the WAN IP if it doesn't already exist
        showmsg info "Checking if route exists for $wan_ip/32 dev $wan_interface table $table"
        if ! ip route show table "$table" | grep -q "$wan_ip/32"; then
            showmsg info "Adding route: $wan_ip/32 dev $wan_interface table $table"
            sudo ip -4 route add "$wan_ip/32" dev "$wan_interface" table "$table"
            if [ $? -eq 0 ]; then
                showmsg "Route for $wan_interface added successfully."
            else
                showmsg error "Failed to add route for $wan_interface."
                continue
            fi
        else
            showmsg info "Route for $wan_ip/32 already exists. Skipping."
        fi

        # Add the default route via WAN interface if it doesn't already exist
        showmsg info "Checking if default route exists for dev $wan_interface table $table"
        if ! ip route show table "$table" | grep -q "default via"; then
            showmsg info "Adding default route: 0.0.0.0/0 dev $wan_interface table $table"
            sudo ip -4 route add 0.0.0.0/0 dev "$wan_interface" table "$table"
            if [ $? -eq 0 ]; then
                showmsg "Default route added successfully."
            else
                showmsg error "Failed to add default route."
                continue
            fi
        else
            showmsg info "Default route for $wan_interface already exists. Skipping."
        fi

        # Increment the priority for the next interface
        ((priority++))
    done
}


# Function to add firewall rules based on LAN-to-WAN interface mapping and port configuration
add_firewall_rules() {
    local lan_interface
    local wan_interface
    local ports
    local port
    local protocol
    local priority=4  # Start with priority 4 for first rule

    # Iterate through each LAN interface and its associated ports
    for lan_interface in "${!lantun[@]}"; do
        wan_interface="${lan_interface/lan/wan}"  # Convert lan interface to corresponding wan interface
        ports="${lantun[$lan_interface]}"
        # Add DNS rule for LAN to WAN direction
        firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 1 -i "$lan_interface" -o "$wan_interface" -p udp --dport 53 -j ACCEPT
        showmsg info "Added rule rule: $lan_interface -> $wan_interface udp 53 for DNS"

        # Add ICMP rule for LAN to WAN direction
        firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 2 -i "$lan_interface" -o "$wan_interface" -p icmp -j ACCEPT
        showmsg info "Added ICMP rule: $lan_interface -> $wan_interface"

        # Add ICMP rule for WAN to LAN direction
        firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 3 -i "$wan_interface" -o "$lan_interface" -p icmp -j ACCEPT
        showmsg info "Added ICMP rule: $wan_interface -> $lan_interface"


        # Loop through each port-protocol pair for the current lan interface
        IFS=',' read -ra port_list <<< "$ports"
        for port_info in "${port_list[@]}"; do
            # Split the port and protocol (e.g., "443/tcp")
            IFS='/' read -r port protocol <<< "$port_info"

            # Add rule for FORWARD direction from LAN to WAN
            firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD $priority -i "$lan_interface" -o "$wan_interface" -p "$protocol" --dport "$port" -j ACCEPT
            showmsg info "Added rule: $lan_interface -> $wan_interface $protocol $port"

            # Increment priority for next rule
            ((priority++))
        done
        firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD $priority -i "$lan_interface" -o "$wan_interface" -j DROP
        showmsg info "Added rule: $lan_interface -> $wan_interface DROP all"
        ((priority++))
        firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD $priority -i "$wan_interface" -o "$lan_interface" -m state --state RELATED,ESTABLISHED -j ACCEPT
        ((priority++))
    done

    # Reload firewall to apply changes
    firewall-cmd --reload
    showmsg "Firewall rules added and reloaded."
}


# Function to remove all direct rules and policies from the firewall
reset_firewall_sys_rules() {
    showmsg info "Bringing down all WireGuard tunnels..."
    bring_down_tunnels
    showmsg info "Reset firewall rules to default..."
    firewall-cmd --reset-to-defaults
    showmsg info "Fetching and removing all direct rules and policies..."

    # List all direct rules
    direct_rules=$(firewall-cmd --direct --get-all-rules)

    if [ -z "$direct_rules" ]; then
        showmsg info "No direct rules found."
    else
        showmsg "Removing direct rules..."
        # Loop through each rule and remove it
        while IFS= read -r rule; do
           # Extract table, chain, priority and rule args from each line
            if [[ $rule =~ ^([a-zA-Z0-9-]+)\ ([a-zA-Z0-9-]+)\ ([a-zA-Z0-9-]+)\ (.+)$ ]]; then
                table="${BASH_REMATCH[1]}"
                chain="${BASH_REMATCH[2]}"
                priority="${BASH_REMATCH[3]}"
                rule_args="${BASH_REMATCH[4]}"

                # Remove the rule using the extracted values
                firewall-cmd --permanent --direct --remove-rule "$table" "$chain" "$priority" $rule_args
                showmsg info "Removed rule: $table $chain $priority $rule_args"
            else
                showmsg info "Skipping invalid rule: $rule"
            fi
            # Remove the rule
            #firewall-cmd --permanent --direct --remove-rule "$rule"
            #echo "Removed rule: $rule"
        done <<< "$direct_rules"
    fi

    # List all policies (ignoring the first policy which is typically the default)
    policies=$(firewall-cmd --get-policies | tail -n +2)  # Skip the first policy

    if [ -z "$policies" ]; then
        showmsg info "No custom policies found."
    else
        showmsg info "Removing custom policies..."
        # Loop through each policy and remove it
        while IFS= read -r policy; do
            firewall-cmd --permanent --remove-policy "$policy"
            showmsg "Removed policy: $policy"
        done <<< "$policies"
    fi

    # Reload firewall to apply changes
    firewall-cmd --reload
    showmsg "All direct rules and policies have been removed and firewall reloaded."
}



# Reset sytem
reset_firewall_sys_rules

# Update lan zone
lan_zone

# Create zone for tun
create_zone 

# Bring Up Tunnels
bring_up_tunnels

# Create Policy drop traffice from tun to default zone public
create_policy 

# Configure routing
configure_routing

# Add Firewall Rules
add_firewall_rules

showmsg "Gateway reload successfully....."
