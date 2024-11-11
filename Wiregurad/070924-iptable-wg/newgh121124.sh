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
declare -a lantun=("lan-t1" "lant-t2")
declare -a wantun=("wan-t1" "wan-t2")

# Physical Interface
declare -a lan_interface=("enp0s8" "enp0s10")
declare -a wan_interface=("enp0s3" "enp0s9")

# Zones Details
declare -A zones=(
    ["lantz"]="lan-t1 wan-t1"
    ["wantz"]="wan-t1 esp1" 
    ["wan"]="wan-t2"    
    ["public"]="wan-t3" 
    ["dmz"]="wan-t4"    
    ["nasz"]="wan-t5"   
)

# Rules
declare -A firewall_rules=(
    ["lan-t1"]="443/tcp 80/tcp 7119/tcp 1179/tcp"
    ["lan-t2"]="443/tcp 80/tcp 7119/tcp 1179/tcp"
)

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
	showmsg "Checking Basic Requiremets for Gateway...."
    # 1. Check if internet is available (ping to google.com)
    if ping -c 1 8.8.8.8 &> /dev/null; then
        showmsg s "Internet is available."
    else
        showmsg e "Internet is not available. Please check your connection."
        return 1
    fi

    # 2. Check if firewalld service is available and running
    if systemctl is-active --quiet firewalld; then
        showmsg s "firewalld service is running."
    else
        showmsg e "firewalld service is not running or not available."
        return 1
    fi

    # 3. Check if wireguard-tools is available
    if command -v wg &> /dev/null; then
        showmsg s "wireguard-tools is installed."
    else
        showmsg e "wireguard-tools is not installed. Please install it."
        return 1
    fi

    # 4. Check if any WireGuard interface files exist in /etc/wireguard
    if ls /etc/wireguard/*.conf &> /dev/null; then
        showmsg s "WireGuard interface files found in /etc/wireguard."
    else
        showmsg e "No WireGuard interface files found in /etc/wireguard."
        return 1
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
            ip rule delete priority "$priority"
            showmsg s "Removed rule with priority: $priority"
        fi
    done
    # Show the remaining rules
    showmsg i "Remaining IP rules:"
    ip rule show
}

remove_interface_from_public_zone(){
	showmsg i "Remove wan interface from Public Zone:"
    for interface in "${wan_interface[@]}"; do
    	 # Check if the interface is part of the public zone
	    if firewall-cmd --zone=public --list-interfaces | grep -q "$interface"; then
	        # If interface is in the public zone, remove it
	        showmsg s "Removing interface $interface from public zone..."
	        firewall-cmd --zone=public --remove-interface="$interface" --permanent
	        showmsg s "Interface $interface removed from public zone."
	        
	    else
	        # If interface is not in the public zone, display a message
	        showmsg s "$interface is not in the public zone. No changes made."
	    fi
    done

    # Reload firewall to apply changes	       
    showmsg s "Firewall reloaded."
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

        # Loop through all default routes and remove them one by one
        for route in $default_routes; do
            # Remove each default route
            ip route del $route
            showmsg s "Removed default route: $route"
        done
        showmsg s "All default routes have been removed."
    fi
}

set_wg_routes() {
    # Step 1: Remove default gateway from the system and flush default route table
    del_default_routes
    ip route flush table default

    # Step 2: Initialize an array to store active interfaces and gateways
    active_interfaces=()

    # Step 3: Loop through each interface in waninterface to set up the default route
    for iface in "${waninterface[@]}"; do
        # Get the gateway for the interface from its config file
        gateway=$(get_gateway "$iface")

        # Log the retrieved gateway
        showmsg s "Gateway for $iface: $gateway"

        # Add default route for this interface to the default routing table
        ip route add default via "$gateway" dev "$iface" table default
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
    fi

    # Step 5: Distribute zones to active interfaces and add routes
    # Split zones for "wan-zone" into an array (e.g., ["zone1" "zone2"])
    IFS=' ' read -r -a wan_zones <<< "${zones["wan-zone"]}"

    # Loop through the zones, assigning each to an active interface in round-robin fashion
    for ((i = 0; i < ${#wan_zones[@]}; i++)); do
        # Get the interface and gateway in a round-robin manner
        iface="${active_interfaces[$((i % ${#active_interfaces[@]}))]}"
        
        # Extract only the interface name from "iface:gateway"
        iface_name="${iface%%:*}"
        # Extract only the gateway from "iface:gateway"
        gw="${iface##*:}"

        # Get the specific zone to assign and the endpoint IP for WireGuard
        zone="${wan_zones[$i]}"
        endpoint_ip=$(get_endpoint_ip "/etc/wireguard/$zone")

        # Add the route using add_route function
        ip route add "$endpoint_ip" via "$gw" dev "$iface_name"        
        showmsg i "Added route for $zone to endpoint $endpoint_ip via $iface_name ($gw)"
    done
}

create_zone_with_default_config() {
    local zone_name="$1"
    local interfaces="$2"
    # Check if the zone already exists
    if firewall-cmd --get-zones | grep -q "$zone_name"; then
        showmsg s "Zone '$zone_name' already exists. Skipping creation."
    else
        # If the zone does not exist, create it
        showmsg s "Creating zone '$zone_name'..."
        firewall-cmd --new-zone="$zone_name" --permanent
        showmsg s "Zone '$zone_name' created."
    fi

    # Set default configuration for the zone
    showmsg s "Configuring zone '$zone_name' with default settings..." 
   	# Only set target to ACCEPT if the zone is not "public"
	if [[ "$zone_name" == "wantz" || "$zone_name" == "lantz" ]]; then
	    firewall-cmd --zone="$zone_name" --set-target=ACCEPT --permanent
	    showmsg i "Adding interfaces '$interfaces' to zone '$zone_name'..."
	    for interface in $interfaces; do
	        firewall-cmd --zone="$zone_name" --add-interface="$interface" --permanent
	        showmsg s "Added interface '$interface' to zone '$zone_name'."
	    done
	else
		firewall-cmd --zone="$zone_name" --set-target=default --permanent
	fi
    # Enable masquerading
    firewall-cmd --zone="$zone_name" --add-masquerade --permanent
    # Reload firewall to apply changes
    firewall-cmd --reload
    showmsg s "Firewall reloaded and changes applied."
}

create_zones(){
	for zone_name in "${!zones[@]}"; do
    	interfaces="${zones[$zone_name]}"
    	create_zone_with_default_config "$zone_name" "$interfaces"
	done
	# Create Zone default ACCEPT
	# Add interface
	# Masqau & FWD enable
}

init_gw(){
	showmsg "Initializing the Gateway please wait...."
	# Remove wan iterface from pulic zone
    # remove_interface_from_public_zone
    # Change Public interface add wg/ssh/http/https port and service enable forwading
    # Create Zones and set interface and default configuration on that zone
    create_zones
    set_wg_routes
}


ensure_system_checks
reset_gw


