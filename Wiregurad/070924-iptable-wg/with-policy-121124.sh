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
echo -e "${CYAN}=                                      =${NC}"
echo -e "${MAGENTA}=      Setting up Gateway V 1.1        =${NC}"
echo -e "${CYAN}=                                      =${NC}"
echo -e "${CYAN}========================================${NC}"
 

# Tunnel Details
declare -a lantun=("lan-t1" "lan-t2")
declare -a wantun=("wan-t1" "wan-t2")

# Physical Interface
declare -a lan_interface=("eno1")
declare -a wan_interface=("eno2" "ens2f0np0")

# Zones Details
declare -A zones=(
    ["lantz"]="lan-t1 lan-t2"
    ["wantz"]="wan-t1 wan-t2" 
    ["external"]="ens2f0np0 eno2"    
    ["public"]="eno1" 
    #["dmz"]="wan-t4"    
    #["nasz"]="wan-t5"   
)
# Policy
declare -a rules=(
    "lantz wantz accept"
    #"lantz dmz accept"
    #"nast nasz accept"
    #"nasz dmz accept"    
)
# Rules
declare -A firewall_rules=(
    ["lan-t1"]="443/tcp 80/tcp 7119/tcp 1179/tcp"
    ["lan-t2"]="443/tcp 80/tcp 7119/tcp 1179/tcp"
)
# For active internet Connections
declare -a active_interfaces=()
# Declare array for valid ports
declare -a validPort=("tcp" "udp" "icmp")
declare -a wg_ports=("51830" "51831" "51832" "51833")
showmsg() {
    if [ "$1" == "i" ]; then
    	echo 
        echo -e "${YELLOW}$2${NC}"        
    elif [ "$1" == "e" ]; then
        echo -e "${RED}$2${NC}"
    elif [ "$1" == "s" ]; then
    	echo -e "${GREEN}$2${NC}"
    else
    	echo
    	echo -e "${CYAN}=============================================${NC}"
        echo -e "${MAGENTA}$1${NC}"
        echo -e "${CYAN}=============================================${NC}"
    fi
}

#Check requirement
ensure_system_checks() {
    showmsg i "Checking Network Manager Service"
    if systemctl is-active --quiet NetworkManager.service; then
        showmsg s "NetworkManager is running. Restarting..."
        sudo systemctl restart NetworkManager.service
    else
        showmsg s "NetworkManager is not running. Starting..."
        sudo systemctl start NetworkManager.service
    fi
	showmsg "Checking Basic Requiremets for Gateway...."
    # 1. Check if internet is available (ping to google.com)
    if ping -c 1 8.8.8.8 &> /dev/null; then
        showmsg s "Internet is available."
    else
        showmsg e "Internet is not available. Please check your connection."
        exit 1
    fi

    # 2. Check if firewalld service is available and running
    if systemctl is-active --quiet firewalld; then
        showmsg s "firewalld service is running."
    else
        showmsg e "firewalld service is not running or not available."
        exit 1
    fi

    # 3. Check if wireguard-tools is available
    if command -v wg &> /dev/null; then
        showmsg s "wireguard-tools is installed."
    else
        showmsg e "wireguard-tools is not installed. Please install it."
        exit 1
    fi

    # 4. Check if any WireGuard interface files exist in /etc/wireguard
    if ls /etc/wireguard/*.conf &> /dev/null; then
        showmsg s "WireGuard interface files found in /etc/wireguard."
    else
        showmsg e "No WireGuard interface files found in /etc/wireguard."
        exit 1
    fi
}

del_direct_rules_firewall(){
	showmsg i "Removing direct rules from firewall..."
	direct_rules=$(firewall-cmd --direct --get-all-rules)
    if [ -z "$direct_rules" ]; then
        showmsg s "No direct rules found."
    else
        
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
                showmsg s "Removed rule: $table $chain $priority $rule_args"
            else
                showmsg s "Skipping invalid rule: $rule"
            fi
        done <<< "$direct_rules"
        firewall-cmd --reload
    fi
}

manage_wireguard() {
    
    # Check if the argument is passed (either "up" or "down")
    if [[ -z "$1" ]]; then
        showmsg e "Usage: $0 up|down"
        exit 1
    fi   

    # Check if the argument is either "up" or "down"
    if [[ "$1" != "up" && "$1" != "down" ]]; then
        showmsg e "Invalid argument. Use 'up' or 'down'."
        exit 1
    fi

    # Loop through all WireGuard configuration files in /etc/wireguard/*.conf
    for conf_file in /etc/wireguard/*.conf; do
        if [[ -f "$conf_file" ]]; then
            # Extract interface name from the .conf file (assuming it's the same as the file name without the .conf extension)
            interface_name=$(basename "$conf_file" .conf)
            
            showmsg i "Attempting to $1 interface: $interface_name"
            
            # Bring the interface up or down based on the argument passed
            wg-quick "$1" "$interface_name"
            
            # Check if the command was successful
            if [[ $? -eq 0 ]]; then
                showmsg s "$interface_name is now $1."
            else
                showmsg e "Failed to $1 $interface_name."
            fi
        fi
    done
}

remove_policies_fw(){
	 showmsg i "Removing custom policies..."
	# List all policies (ignoring the first policy which is typically the default)
	policies=$(firewall-cmd --get-policies | tail -n +2)  # Skip the first policy

	if [ -z "$policies" ]; then
	    showmsg s "No custom policies found."
	else	   
	    # Loop through each policy and remove it
	    while IFS= read -r policy; do
	        # Ensure the policy is not empty
	        if [ -n "$policy" ]; then
	            firewall-cmd --permanent --remove-policy "$policy"
	            showmsg s "Removed policy: $policy"
	        fi
	    done <<< "$policies"
	    # Reload firewall to apply changes
		firewall-cmd --reload
		showmsg s "All custom policies have been removed and firewall reloaded."
	fi
	
}

flush_ip_rules() { 
	showmsg i "Flushing IP rules to default"    
    # List all IP rules
    ip_rules=$(ip rule show)
    echo "$ip_rules" | while read -r rule; do
        priority=$(echo "$rule" | awk '{print $1}')       
        if [[ "$priority" != "0:" && "$priority" != "32766:" && "$priority" != "32767:" ]]; then 
            ip rule delete priority "${priority%%:}"
            showmsg s "Removed rule with priority: $priority"
        fi
    done
    # Show the remaining rules
    showmsg i "Remaining IP rules:"
    ip rule show
}

remove_interface_from_public_zone(){
	showmsg i "Remove interface from Public Zone:"
    currentiface=$(firewall-cmd --zone=public --list-interfaces)
    # Retrieve the interfaces allowed in the public zone
    allowed_interfaces="${zones["public"]}"

    for interface in $current_interfaces; do
        # Check if the interface is NOT in the allowed list
        if ! echo "$allowed_interfaces" | grep -qw "$interface"; then
            # Remove the interface from the public zone
            firewall-cmd --zone=public --remove-interface="$interface" --permanent
            showmsg s "Removed interface '$interface' from public zone."
        fi
    done
    # Add any missing allowed interfaces to the public zone
    for interface in $allowed_interfaces; do
        if ! echo "$current_interfaces" | grep -qw "$interface"; then
            firewall-cmd --zone=public --add-interface="$interface" --permanent
            showmsg s "Added interface '$interface' to public zone."
        fi
    done
    # Reload firewall to apply changes
    showmsg s "Reloading firewall to apply changes."
    firewall-cmd --reload
}

reset_gw(){

	showmsg "Reset the Gateway please wait..."
	showmsg i "Checking Network Manager Service"
	if systemctl is-active --quiet NetworkManager.service; then
	    showmsg s "NetworkManager is running. Restarting..."
	    sudo systemctl restart NetworkManager.service
	else
	    showmsg s "NetworkManager is not running. Starting..."
	    sudo systemctl start NetworkManager.service
	fi
	sudo systemctl stop NetworkManager.service
	showmsg i "Stop WireGuarg if already running"	
	manage_wireguard down	
	# Check if firewalld is running
    if ! systemctl is-active --quiet firewalld; then       
        sudo systemctl start firewalld
        if [[ $? -eq 0 ]]; then
            showmsg s "Firewalld started successfully."
        else
            showmsg e "Failed to start firewalld."
        fi
    fi
    showmsg i "Reset firewall rules to default..."
    firewall-cmd --reset-to-defaults		
	# Delete Direct rule
	del_direct_rules_firewall
	# Remove all policy except default in firewall
	remove_policies_fw
	# Flush Ip rule
	flush_ip_rules
	# Show current Ip routes	
    showmsg i "Remaining IP routes:"
    ip route show all    
}

del_default_routes(){
    showmsg i "Removing default routes from Gateway..."

    # Get all default routes
    default_routes=$(ip route show default)

    # Check if there are any default routes
    if [ -z "$default_routes" ]; then
        showmsg s "No default routes found."
    else
        # Show found default routes
        showmsg s "Found the following default routes:"
        echo "$default_routes"
        while IFS= read -r route; do
            # Print the line with the line number
            ip route del $route
            showmsg s "Removed default route: $route"            
        done <<< "$default_routes"       
        showmsg s "All default routes have been removed."
    fi
}

get_gateway() {
    local iface=$1
    local config_file="/etc/NetworkManager/system-connections/${iface}.nmconnection"

    if [[ -f "$config_file" ]]; then
        local gateway=$(grep '^address1=' "$config_file" | awk -F, '{print $2}')
        echo "$gateway"
    else
        echo "Error: Configuration file for interface $iface not found." >&2
        return 1
    fi
}

get_active_connections() {
    showmsg "Check active connection"
    # Step 1: Remove default gateway from the system and flush default route table
    del_default_routes
    ip route flush table default

    # Step 3: Loop through each interface in waninterface to set up the default route
    for iface in "${wan_interface[@]}"; do
        # Get the gateway for the interface from its config file
        gateway=$(get_gateway "$iface")

        # Log the retrieved gateway
        showmsg s "Gateway for $iface: $gateway"
        if ! ip rule show | grep -q "32767:.*from all lookup default"; then
            # Add the rule if it doesn't exist
            ip rule add priority 32767 lookup default        
        fi
        # Add default route for this interface to the default routing table
        ip route add default via "$gateway" dev "$iface" proto static metric 100 table default 
        showmsg s "Added default route for $iface to ping 8.8.8.8"

        # Check if the interface can successfully reach 8.8.8.8
        if ping -I "$iface" -c 1 -W 1 8.8.8.8 > /dev/null 2>&1; then
            # Add the interface and its gateway to the active_interfaces array
            active_interfaces+=("$iface:$gateway")
            showmsg s "Ping successful on $iface, added to active interfaces"
        else
            showmsg e "Ping failed on $iface, skipping interface"
        fi        
        # Remove the default route to avoid conflicts with subsequent interfaces
        ip route flush table default
        showmsg s "Removed temporary default route for $iface"
    done

    # Step 4: Check if any active interfaces were found
    if [ ${#active_interfaces[@]} -eq 0 ]; then
        showmsg e "No active interfaces found, exiting."
        exit 1
    else
        showmsg s "${active_interfaces[*]} are available for gateway"
    fi
}

set_public_zone(){
    showmsg i "Configure Public Zone"
    local interfaces="${zones['public']}"
     # Add interfaces to the zone
    # showmsg s "Adding interfaces '$interfaces' to zone '$zone_name'..."
    # for interface in $interfaces; do
    #     firewall-cmd --zone="$zone_name" --add-interface="$interface" --permanent
    #     showmsg s "Added interface '$interface' to zone '$zone_name'."
    # done
    for wgp in "${wg_ports[@]}"; do
        showmsg s "Adding wiregard $wgp ports for client use"
        firewall-cmd --permanent --zone="public" --add-port="$wgp"/udp
    done
    # Set Forwaing enablde
    showmsg s "Adding forwading in public"
    firewall-cmd --zone=public --add-forward --permanent

    # Enable masquerading for the zone
    firewall-cmd --zone=public --add-masquerade --permanent
    showmsg s "Masquerading enabled for zone public."
    # Reload firewall to apply all changes
    firewall-cmd --reload
    showmsg s "Firewall reloaded and changes applied."     
        
}
add_interface_zones() {    
    for zone_name in "${!zones[@]}"; do
        local interfaces="${zones[$zone_name]}"
        showmsg s "Adding interfaces '$interfaces' to zone '$zone_name'..."
        for interface in $interfaces; do
            firewall-cmd --zone="$zone_name" --add-interface="$interface" --permanent
            showmsg s "Added interface '$interface' to zone '$zone_name'."
        done
        firewall-cmd --reload
        showmsg s "Firewall reloaded and changes applied."
    done    
}
create_zone_with_default_config() {
    showmsg i "Creating new zones as per Gateway requirements...."
    # Loop through each zone in the zones array
    for zone_name in "${!zones[@]}"; do
        # Check if the zone already exists
        if firewall-cmd --get-zones | grep -q "$zone_name"; then
            showmsg s "Zone '$zone_name' already exists. Skipping creation."
        else
            # If the zone does not exist, create it
            showmsg s "Creating zone '$zone_name'..."
            firewall-cmd --permanent --new-zone="$zone_name"
            showmsg s "Zone '$zone_name' created."
        fi

        # Set default configuration for the zone
        showmsg i "Configuring zone '$zone_name' with default settings..."
        
        # Set target to ACCEPT for specific zones if policy is not set
        # if [[ "$zone_name" == "wantz" || "$zone_name" == "lantz" ]]; then
        #     firewall-cmd --zone="$zone_name" --set-target=ACCEPT --permanent
        # else
        #     firewall-cmd --zone="$zone_name" --set-target=default --permanent
        # fi       
        # Implement Policy
        firewall-cmd --zone="$zone_name" --set-target=DROP --permanent
        # Set Forwaing enablde
        showmsg s "Adding forwading in $zone_name"
        firewall-cmd --zone="$zone_name" --add-forward --permanent

        # Enable masquerading for the zone
        firewall-cmd --zone="$zone_name" --add-masquerade --permanent
        showmsg s "Masquerading enabled for zone '$zone_name'."
    done    

    # Reload firewall to apply all changes
    firewall-cmd --reload
    showmsg s "Firewall reloaded and changes applied."
}
# Function to fetch the IP address of the corresponding WAN interface
get_wan_ip() {
    local iface=$1
    local config_file="/etc/wireguard/${iface}.conf"

    if [[ -f "$config_file" ]]; then
        local gateway=$(grep "Address" $config_file | awk -F' = |/' '{print $2}')
        echo "$gateway"
    else
        showmsg e "Error: Configuration file for interface $iface not found." >&2
        return 1
    fi
}

set_routing_lan_tunnels(){   
    local priority=206
    local table=123
    for interface in "${lantun[@]}"; do        
        showmsg i "Adding routing for $interface tunnel"
        wan_interface="${interface/lan/wan}"
        # 1. Fetch the corresponding WAN IP
        wan_ip=$(get_wan_ip "$wan_interface")
        if [ -z "$wan_ip" ]; then
            showmsg e "Failed to fetch WAN IP for $interface. Skipping this interface."
            continue
        fi
        # 2. Add routing table for this lan interface
        showmsg s "Checking if ip rule exists: iif $interface table $table priority $priority"
        if ! ip rule show | grep -q "iif $interface lookup $table"; then
            showmsg s "Adding ip rule: iif $interface table $table priority $priority"
            sudo ip rule add iif "$interface" table "$table" priority "$priority"
            if [ $? -eq 0 ]; then
                showmsg s "ip rule added for $interface."
            else
                showmsg e "Failed to add ip rule for $interface."
                continue
            fi
        else
            showmsg s "ip rule for $interface already exists. Skipping."
        fi

        #3. Add the route for the WAN IP if it doesn't already exist
        showmsg s "Checking if route exists for $wan_ip/32 dev $wan_interface table $table"
        if ! ip route show table "$table" | grep -q "$wan_ip/32"; then
            showmsg s "Adding route: $wan_ip/32 dev $wan_interface table $table"
            sudo ip -4 route add "$wan_ip/32" dev "$wan_interface" table "$table"
            if [ $? -eq 0 ]; then
                showmsg s "Route for $wan_interface added successfully."
            else
                showmsg e "Failed to add route for $wan_interface."
                continue
            fi
        else
            showmsg s "Route for $wan_ip/32 already exists. Skipping."
        fi

        #4. Add the default route via WAN interface if it doesn't already exist
        showmsg s "Checking if default route exists for dev $wan_interface table $table"
        if ! ip route show table "$table" | grep -q "default via"; then
            showmsg s "Adding default route: 0.0.0.0/0 dev $wan_interface table $table"
            sudo ip -4 route add 0.0.0.0/0 dev "$wan_interface" table "$table"
            if [ $? -eq 0 ]; then
                showmsg s "Default route added successfully."
            else
                showmsg e "Failed to add default route."
                continue
            fi
        else
            showmsg s "Default route for $wan_interface already exists. Skipping."
        fi
        ((priority++))
        ((table++))
    done
}

# Function to get the endpoint IP from the WireGuard config
get_endpoint_ip() {
    local config_file=$1
    local endpoint_ip=$(grep 'Endpoint' "$config_file".conf | grep -v '^#' | awk -F '[ :]' '{print $3}')
    echo "$endpoint_ip"
}

set_routing_wan_tunnels(){
    showmsg i "Adding routing for Secure/Wan tunnels"
    # Step 1 Check if any active interfaces were found
    if [ ${#active_interfaces[@]} -eq 0 ]; then
        showmsg e "No active interfaces found, exiting."
        exit 1
    fi

    # Step 2: Distribute zones to active interfaces and add routes
    # Split zones for "wantz-zone" into an array (e.g., ["eth1" "eth2"])
    IFS=' ' read -r -a wan_zones <<< "${zones["wantz"]}"

    # Loop through the zones, assigning each to an active interface in round-robin fashion
    for ((i = 0; i < ${#wan_zones[@]}; i++)); do
        # Get the interface and gateway in a round-robin manner
        iface="${active_interfaces[$((i % ${#active_interfaces[@]}))]}"        
        # Extract only the interface name from "iface:gateway"
        iface_name="${iface%%:*}"
        # Extract only the gateway from "iface:gateway"
        gw="${iface##*:}"
        # Get the specific zone to assign and the endpoint IP for WireGuard
        wan_tun="${wan_zones[$i]}"
        endpoint_ip=$(get_endpoint_ip "/etc/wireguard/$wan_tun")
        # Add the route using add_route function
        if ! ip route show | grep -q "$endpoint_ip via $gw dev $iface_name"; then
            ip route add "$endpoint_ip" via "$gw" dev "$iface_name"
            # "$endpoint_ip" via "$gateway" dev "$iface"add_route "$iface_name"  "$gw"
            showmsg s "Added route for $zone to endpoint $endpoint_ip via $iface_name ($gw)"
        else
            showmsg s "Route for $endpoint_ip via $gw on $iface_name already exists"
        fi        
    done
}

create_firewall_rules(){
    local lan_interface
    local wan_interface
    local ports
    local port
    local protocol
    local priority=0  # Start with priority 4 for first rule

    # Iterate through each LAN interface and its associated ports
    for lan_interface in "${lantun[@]}"; do
        wan_interface="${lan_interface/lan/wan}"  # Convert lan interface to corresponding wan interface
        ports="${firewall_rules[$lan_interface]}"
        # Add DNS rule for LAN to WAN direction
        firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD $priority -i "$lan_interface" -o "$wan_interface" -p udp --dport 53 -j ACCEPT
        showmsg s "Added rule rule: $lan_interface -> $wan_interface udp 53 for DNS"

        # Add ICMP rule for LAN to WAN direction
        firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD $priority -i "$lan_interface" -o "$wan_interface" -p icmp -j ACCEPT
        showmsg s "Added ICMP rule: $lan_interface -> $wan_interface"

        # Add ICMP rule for WAN to LAN direction
        firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD $priority -i "$wan_interface" -o "$lan_interface" -p icmp -j ACCEPT
        showmsg s "Added ICMP rule: $wan_interface -> $lan_interface"


        # Loop through each port-protocol pair for the current lan interface
        IFS=' ' read -ra port_list <<< "$ports"  # Split using space as the delimiter
        for port_info in "${port_list[@]}"; do
            # Split the port and protocol (e.g., "443/tcp")
            IFS='/' read -r port protocol <<< "$port_info"
            
            # Validate protocol
            if [[ ! " ${validPort[@]} " =~ " ${protocol} " ]]; then
                showmsg e "Invalid protocol: $protocol in $port_info. Skipping rule."
                continue
            fi

            # Validate port is a number (optional, you can also allow ranges or other checks)
            if ! [[ "$port" =~ ^[0-9]+$ ]]; then
                showmsg e "Invalid port number: $port in $port_info. Skipping rule."
                continue
            fi

            # Add rule for FORWARD direction from LAN to WAN
            firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD $priority -i "$lan_interface" -o "$wan_interface" -p "$protocol" --dport "$port" -j ACCEPT
            showmsg s "Added rule: $lan_interface -> $wan_interface $protocol $port"

            # Increment priority for next rule
            # ((priority++))
        done        
        firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD $priority -i "$wan_interface" -o "$lan_interface" -m state --state RELATED,ESTABLISHED -j ACCEPT
        # ((priority++))
        firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD $priority -i "$lan_interface" -o "$wan_interface" -j DROP
        showmsg s "Added rule: $lan_interface -> $wan_interface DROP all"
        # ((priority++))
    done

    # Reload firewall to apply changes
    firewall-cmd --reload
    showmsg i "Firewall rules added and reloaded."
}

create_gateway_policy(){
    local default_action="DROP"
    
    # Ensure firewalld is running
    firewall-cmd --state &> /dev/null || {
        showmsg e "Error: firewalld is not running. Starting firewalld..."
        systemctl start firewalld
    }

    # Step 1: Set default drop policy
    showmsg i "Setting default policy to drop for all zones..."
    for zone in $(firewall-cmd --get-zones); do
        firewall-cmd --permanent --zone="$zone" --set-target=DROP
    done
    firewall-cmd --reload

    # Step 2: Apply accept rules from the array
    showmsg i "Applying custom accept policies based on rules array..."
    for rule in "${rules[@]}"; do
        # Read source zone, destination zone, and action
        read -r src_zone dst_zone action <<< "$rule"
        
        # Apply the accept policy only if action is "accept"
        if [[ "$action" == "accept" ]]; then
            policy_name="${src_zone}_to_${dst_zone}_a"
            showmsg s "Creating policy $policy_name: $src_zone -> $dst_zone ACCEPT"

            # Create policy if it doesn't already exist
            if ! firewall-cmd --get-policies | grep -q "$policy_name"; then
                firewall-cmd --permanent --new-policy="$policy_name"
                firewall-cmd --permanent --policy="$policy_name" --add-ingress-zone="$src_zone"
                firewall-cmd --permanent --policy="$policy_name" --add-egress-zone="$dst_zone"
                firewall-cmd --permanent --policy="$policy_name" --set-target=ACCEPT
            else
                showmsg s "Policy $policy_name already exists, skipping creation."
            fi
        fi
    done

    # Reload firewall to apply changes
    showmsg s "Reloading firewall to apply new policies..."
    firewall-cmd --reload
    showmsg s "Policies applied successfully."
}

init_gw(){
    # Initila Script to reset gateway
    ensure_system_checks
    reset_gw
    #
	showmsg "Initializing the Gateway please wait...."	
    create_zone_with_default_config
    # showmsg "Removing default interface from public zone..."
    remove_interface_from_public_zone
    showmsg "Setup public zone for gateway"
    set_public_zone
    showmsg "Adding Interfaces to Zones"
    add_interface_zones
    showmsg "Get Active Connections"
    get_active_connections
    showmsg "Bringup gateway tunnels"
    manage_wireguard up
    showmsg "Setup Routing for Lan tunnels"
    set_routing_lan_tunnels
    showmsg "Setup Routing for Secure/Wan tunnels"
    set_routing_wan_tunnels
    showmsg "Setup firewall direct rules"
    create_firewall_rules
    showmsg "Setup firewall policies" 
    create_gateway_policy
}

init_gw
showmsg "Gateway Initialization is complete"
