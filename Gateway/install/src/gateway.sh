#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color
export TOP_PID=$$

help () {
  printf "============================================================================\n"
  printf "+                            Gateway Script 1.3                            +\n"
  printf "============================================================================\n"
  printf "|                                                                          |\n"
  printf "| Available options:                                                       |\n"
  printf "|    1): To start Gateway.                                                 |\n"
  printf "|    2): To re-start Gateway.                                              |\n"
  printf "|    3): To stop Gateway                                                   |\n"
  printf "|    4): To reset Gateway                                                  |\n"
  printf "|    5): To debug Gateway                                                  |\n"
  printf "|    0): To exit from Gateway script                                       |\n"
  printf "============================================================================\n"
  printf "|               Thank you for using! Remember me for this work ;)          |\n"
  printf "============================================================================\n"
  sleep 1
}
 
##########################################
# VPN/Secure Tunnels Details Only 
##########################################
# Client Side
declare -a lantun=()
# Wan/InternetSide
declare -a wantun=()

##########################################
# Physical interfaces required
# for gateway to create tunnels
##########################################
# Client Side to connect wg
declare -a lan_interface=()
# Internet interface to connect wg tunnels
declare -a wan_interface=()

##########################################
# Zones Details
# Add zone and their respective interfaces
##########################################
declare -A zones=()

##########################################
# DMZ can be accessed via tunnel only
# Mention the tunnel allowed to access DMZ (default lan-t1)
##########################################
declare dmz_interface
declare -A dmz_service_name=()
declare a dmz_access_via=()

##########################################
# Firewall policy between zones 
# By default, all are in drop state
##########################################
declare -a firewall_policies=()

##########################################
# If routing traffic between two zones interfaces, 
# create policy then add rules for allowed traffic
##########################################
declare -A firewall_direct_rules=()

# For active internet Connections
declare -a active_interfaces=()
# Declare array for valid ports
declare -a validPort=("tcp" "udp" "icmp")
# Ports required on LAN to connect clients
declare -a lan_side_ports=("5000/tcp")

# Access config file 
config_file="/root/gateway/gw-config.ini"
sed -i 's/\r//g' "$config_file"
if [[ -f "$config_file" ]]; then
    source "$config_file"
else
    echo "Config file not found at $config_file. Exiting..."
    kill $TOP_PID
fi

showmsg() {
    case "$1" in
        "i")
            # Info message (yellow)
            echo -e "${YELLOW}$2${NC}"
            ;;
        "e")
            # Error message (red)
            echo -e "${RED}$2${NC}"
            ;;
        "s")
            # Success message (green)
            echo -e "${GREEN}$2${NC}"
            ;;
        *)
            # Default case (cyan and magenta border)
            echo -e "${CYAN}=============================================${NC}"
            echo -e "${MAGENTA}$1${NC}"
            echo -e "${CYAN}=============================================${NC}"
            ;;
    esac
}

check_system_details(){
    showmsg i "Current routes on Gateway are:"
    ip route show all
    showmsg i "Current rules on Gateway are:"
    ip rule show all
    showmsg i "Active Interfaces are"
    ip -4 -br a
    showmsg i "Checking required service status"
    if systemctl is-active --quiet firewalld; then
        showmsg s "firewalld is running"
    else
        systemctl start firewalld
        showmsg s "firewalld service started"
    fi  
    check_ping && showmsg s "Internet is working" || showmsg e "Internet not working"
    # Check if wireguard is installed
    if command -v wg &> /dev/null; then
        showmsg s "wg is installed."
    else
        showmsg e "wg is not installed. Please install it."
        kill $TOP_PID
    fi
    # Check if config file is available in wireguard folder
    if ! ls /etc/wireguard/*.conf &> /dev/null; then
        showmsg e "No WireGuard interface files found in /etc/wireguard."
        kill $TOP_PID
    fi
}

check_ping() {
    ping -c 1 8.8.8.8 &>/dev/null && return 0 || return 1
}

get_wireguard_info() {
    local wg_iface="$1"
    local param="$2"
    local config_file
    local result
    config_file="/etc/wireguard/${wg_iface}.conf"
    if [[ ! -f "$config_file" ]]; then
        echo "Config file not found: $config_file"
        return 1
    fi
    case "$param" in
        "ip")          
            result=$(grep -i "Address" "$config_file" | awk -F'=' '{split($2, a, "/"); print a[1]}' | tr -d '[:space:]')
            if [[ -n "$result" ]]; then
                echo "$result"
            else                
                return 1
            fi
            ;;
        "endpoint")           
            result=$(grep -i "Endpoint" "$config_file" | awk -F'=' '{split($2, a, ":"); print a[1]}' | tr -d '[:space:]')
            if [[ -n "$result" ]]; then
                echo "$result"
            else                
                return 1
            fi
            ;;
        *)
            return 1
            ;;
    esac
}
get_nic_info(){
    local interface=$1
    local info_type=$2
    local config_file
    local result
    config_file="/etc/NetworkManager/system-connections/$interface.nmconnection"
    if [[ ! -f "$config_file" ]]; then
        showmsg e "Error: Network configuration file for $interface not found."
        return 1
    fi
    case "$info_type" in
        "ip")           
            result=$(grep -i "address1" "$config_file" | awk -F= '{print $2}' | tr -d ' ')
            if [[ -n "$result" ]]; then
                echo "$result"
            else                
                return 1
            fi
            ;;
        "gateway")
           result=$(grep -i "address1" "$config_file" | awk -F= '{print $2}' | tr -d ' ' | cut -d',' -f2)
            if [[ -n "$result" ]]; then
                echo "$result"
            else                
                return 1
            fi
            ;;
        *)            
            return 1
            ;;
    esac
}

start_stop_networkmanager(){
    check_status() {
        systemctl is-active --quiet NetworkManager
    }

    if ! check_status; then
        # NetworkManager is not running, start it
        showmsg s "NetworkManager is not running. Starting NetworkManager..."
        sudo systemctl start NetworkManager
        # Wait for the service to start
        sudo systemctl is-active --quiet NetworkManager && showmsg s "NetworkManager started successfully." || showmsg e "Failed to start NetworkManager."
    else
        # NetworkManager is running, restart it
        showmsg s "NetworkManager is already running. Restarting..."
        sudo systemctl restart NetworkManager
        # Wait for the service to restart
        sudo systemctl is-active --quiet NetworkManager && showmsg s "NetworkManager restarted successfully." || showmsg e "Failed to restart NetworkManager."
    fi
    sudo systemctl stop NetworkManager  
}

clear_ip_rules_and_flush_tables(){
    local table
    local routefile="/root/gateway/routes"    
    ip route flush table default 
    # Remove all IP rules except for the 'local', 'main', and 'default'
    ip rule show all | grep -vE 'from all lookup (local|main|default)' | awk -F: '{print $1}' | while read prefix; do
        table=$(ip rule show all | grep "$prefix" | awk '{for(i=1;i<=NF;i++) if($i=="lookup") print $(i+1)}')
        ip route flush table $table
        ip rule del pref $prefix
        showmsg s "$table flushed and removed from ip rule and routes"
    done
    if ip rule show | grep -q "suppress_prefixlength 0"; then   
        ip rule del lookup main suppress_prefixlength 0
    fi  
    if [ -f "$routefile" ]; then
        while IFS= read -r line; do
           ip route del $line           
        done < "$routefile"
    fi     
    > "$routefile"
}

remove_all_default_routes(){
    local routefile="/root/gateway/default-routes" 
    showmsg i "Removing all default route form system"
    ip route show all | grep default >> "$routefile"
    ip route show all | grep default | awk '{print $1, $2, $3}' | while read -r route; do ip route del $route; done 
}
add_default_route(){
    local routefile="/root/gateway/default-routes"  
    if [ -f "$routefile" ]; then
        while IFS= read -r line; do
           ip route add $line           
        done < "$routefile"
    fi  
    > "$routefile"
    # local i=0
    # for iface in "${wan_interface[@]}"; do      
    #     gateway=$(get_nic_info "$iface" "gateway")
    #     src_ip=$(ip addr show "$iface" | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
    #     route="default via $gateway dev $iface proto static src $src_ip metric 10$i" 
    #     if ! ip route show | grep -q "$route"; then
    #         echo "Adding route: $route"
    #         ip route add default via "$gateway" dev "$iface" proto static src "$src_ip" metric 10"$i" 
    #     fi
    #     ((i++))        
    # done  
}
manage_wireguard() { 
    showmsg i "Reset the wireguard interface" 
    if [[ -z "$1" ]]; then
        showmsg e "Usage: $0 up|down"
        exit 1
    fi
    if [[ "$1" != "up" && "$1" != "down" ]]; then
        showmsg e "Invalid argument. Use 'up' or 'down'."
        exit 1
    fi
    for conf_file in /etc/wireguard/*.conf; do
        if [[ -f "$conf_file" ]]; then
            interface_name=$(basename "$conf_file" .conf)
            if wg show "$interface_name" 2>/dev/null | grep -q "interface: $interface_name"; then
                current_status="up"
            else
                current_status="down"
            fi

            # If the argument is "up" and interface is down, bring it up
            if [[ "$1" == "up" && "$current_status" == "down" ]]; then                
                wg-quick up "$interface_name"
                if [[ $? -eq 0 ]]; then
                    showmsg s "$interface_name is now up."
                else
                    showmsg e "Failed to bring $interface_name up."
                fi           
            elif [[ "$1" == "up" && "$current_status" == "up" ]]; then                
                wg-quick down "$interface_name" && \
                wg-quick up "$interface_name"
                if [[ $? -eq 0 ]]; then
                    showmsg s "$interface_name is now up."
                else
                    showmsg e "Failed to bring $interface_name up."
                fi
            # If the argument is "down" and interface is up, bring it down
            elif [[ "$1" == "down" && "$current_status" == "up" ]]; then               
                wg-quick down "$interface_name"
                if [[ $? -eq 0 ]]; then
                    showmsg s "$interface_name is now down."
                else
                    showmsg e "Failed to bring $interface_name down."
                fi           
            elif [[ "$1" == "down" && "$current_status" == "down" ]]; then
                showmsg s "$interface_name is already down. No action required."
            fi
        fi
    done
}

check_active_internet_interfaces(){
  remove_all_default_routes
  ip route flush table default 
  for iface in "${wan_interface[@]}"; do
    gateway=$(get_nic_info "$iface" "gateway")
    if [[ $? -eq 0 ]]; then
      ip route add 8.8.8.8 via "$gateway" table default
      check_ping && active_interfaces+=("$iface") 
      ip route flush table default   
    fi
  done
  if [ ${#active_interfaces[@]} -eq 0 ]; then
    showmsg i "We are unable to found any interface that are connected with internet please check internet or config file where you have mentioned the wan interface name"
    showmsg e "We are exiting..."
    kill $TOP_PID
  else
    showmsg i "Active interface on system with internet are:"
    echo $active_interfaces
  fi  
}

setting_up_routing_lan_secure_tunnel(){        
    local priority=206
    local table=123
    local wan_ifcae
    local wan_ip
    for interface in "${lantun[@]}"; do  
        showmsg i "Adding routing for $interface tunnel"
        wan_ifcae="${interface/lan/wan}"
        # 1. Fetch the corresponding WAN IP
        wan_ip=$(get_wireguard_info "$wan_ifcae" "ip")              
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
        showmsg s "Checking if route exists for $wan_ip/32 dev $wan_ifcae table $table"
        if ! ip route show table "$table" | grep -q "$wan_ip/32"; then
            showmsg s "Adding route: $wan_ip/32 dev $wan_ifcae table $table"
            sudo ip -4 route add "$wan_ip/32" dev "$wan_ifcae" table "$table"
            if [ $? -eq 0 ]; then
                showmsg s "Route for $wan_ifcae added successfully."
            else
                showmsg e "Failed to add route for $wan_ifcae."
                continue
            fi
        else
            showmsg s "Route for $wan_ip/32 already exists. Skipping."
        fi

        #4. Add the default route via WAN interface if it doesn't already exist
        showmsg s "Checking if default route exists for dev $wan_ifcae table $table"
        if ! ip route show table "$table" | grep -q "default via"; then
            showmsg s "Adding default route: 0.0.0.0/0 dev $wan_ifcae table $table"
            sudo ip -4 route add 0.0.0.0/0 dev "$wan_ifcae" table "$table"
            if [ $? -eq 0 ]; then
                showmsg s "Default route added successfully."
            else
                showmsg e "Failed to add default route."
                continue
            fi
        else
            showmsg s "Default route for $wan_ifcae already exists. Skipping."
        fi
        #5. Add DMZ rule if exits
        if [[ " ${dmz_access_via[@]} " =~ " $interface " ]]; then
            if [ ! -n "$dmz_interface" ]; then
                showmsg e "Define DMZ interface in gw-config file"
                kill $TOP_PID
            fi
            # Loop through dmz_service_name associative array
            for service in "${!dmz_service_name[@]}"; do
                service_ip=${dmz_service_name[$service]}                
                ip route add "$service_ip" dev "$dmz_interface" table "$table"
            done
            showmsg s "DMZ rules added successfully for $interface"
        fi
        
        ((priority++))
        ((table++))
    done
}

setting_up_routing_wan_secure_tunnel(){
    showmsg i "Adding routing for Secure/Wan tunnels"
    local routefile="/root/gateway/routes"
    local endpoint
    local active_iface    
    local gateway
    local num_active
    # Step 1 Check if any active interfaces were found
    if [ ${#active_interfaces[@]} -eq 0 ]; then
        showmsg e "No active interfaces found, exiting."
        exit 1
    fi

    i=0
    num_active=${#active_interfaces[@]}  # Number of active interfaces
    for interface in "${wantun[@]}"; do
        endpoint=$(get_wireguard_info "$interface" "endpoint")
        active_iface=${active_interfaces[$((i % num_active))]}  # Wrap index using modulo
        gateway=$(get_nic_info "$active_iface" "gateway")
        if ! ip route show | grep -q "$endpoint via $gateway dev $active_iface"; then           
            echo "$endpoint via $gateway dev $active_iface" >> "$routefile"
            ip route add "$endpoint" via "$gateway" dev "$active_iface"
            showmsg s "Added route for $interface to endpoint $endpoint via $active_iface ($gateway)"
        else            
            showmsg s "Route for $endpoint via $gateway on $active_iface already exists"
        fi
        ((i++))  
    done
   #  local j
   # # num_active=${#active_interfaces[@]}   
   #  for interface in "${wantun[@]}"; do 
   #      j=0
   #      if [[ ! -n ${num_active[$j]} ]]; then
   #          j=0
   #          active_iface=${active_interfaces[$j]}
   #          echo "$active_iface changed again"
   #      else
   #          active_iface=${active_interfaces[$j]}
   #      fi   
   #      endpoint=$(get_wireguard_info "$interface" "endpoint")       
   #      gateway=$(get_nic_info "$active_iface" "gateway")      
   #      if ! ip route show | grep -q "$endpoint via $gateway dev $active_iface"; then
   #          # Add the route
   #          echo "$endpoint via $gateway dev $active_iface" >> "$routefile"
   #          ip route add "$endpoint" via "$gateway" dev "$active_iface"
   #          showmsg s "Added route for $interface to endpoint $endpoint via $active_iface ($gateway)"
   #      else           
   #          showmsg s "Route for $endpoint via $gateway on $active_iface already exists"
   #      fi
   #      ((j++))
   #  done
   
}

remove_direct_rules_fw(){
    direct_rules=$(firewall-cmd --direct --get-all-rules)

    if [ -z "$direct_rules" ]; then
        showmsg s "No direct rules found."
    else
        showmsg i "Removing direct rules..."
        # Loop through each rule and remove it
        while IFS= read -r rule; do
           # Extract table, chain, priority and rule args from each line
            if [[ $rule =~ ^([a-zA-Z0-9-]+)\ ([a-zA-Z0-9-]+)\ ([a-zA-Z0-9-]+)\ (.+)$ ]]; then
                table="${BASH_REMATCH[1]}"
                chain="${BASH_REMATCH[2]}"
                priority="${BASH_REMATCH[3]}"
                rule_args="${BASH_REMATCH[4]}"
                firewall-cmd --permanent --direct --remove-rule "$table" "$chain" "$priority" $rule_args
                showmsg s "Removed rule: $table $chain $priority $rule_args"
            else
                showmsg s "Skipping invalid rule: $rule"
            fi           
        done <<< "$direct_rules"
    fi 
    firewall-cmd --reload
}
remove_policies_fw(){
    showmsg i "Removing custom policies..."   
    policies=$(firewall-cmd --get-policies | tail -n +2)
    if [ -z "$policies" ]; then
        showmsg s "No custom policies found."
    else 
        while IFS= read -r policy; do           
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
reset_fw(){
    showmsg "Resting firewall to default state"
    firewall-cmd --reset-to-defaults && \
    firewall-cmd --add-port=5000/tcp --permanent && \
    firewall-cmd --reload
    remove_direct_rules_fw 
    remove_policies_fw 
}

create_zones_with_default_settings(){
    showmsg i "Create zone required for gateway"
    for zone_name in "${!zones[@]}"; do
        if firewall-cmd --get-zones | grep -q "$zone_name"; then
            showmsg s "Zone '$zone_name' already exists. Skipping creation."
        else
            # If the zone does not exist, create it
            showmsg s "Creating zone '$zone_name'..."
            firewall-cmd --permanent --new-zone="$zone_name"            
        fi
        firewall-cmd --permanent --zone="$zone_name" --set-target=DROP  && \
        firewall-cmd --permanent --zone="$zone_name" --add-forward  && \
        firewall-cmd --permanent --zone="$zone_name" --add-masquerade 
    done     
    showmsg s "Reloading firewall after creating zones"
    firewall-cmd --reload
    configure_public_zone
}

configure_public_zone(){
    showmsg s "Setting up public zone"
     for port in "${lan_side_ports[@]}"; do
        if ! firewall-cmd --permanent --zone=public --list-ports | grep -q "$port"; then
            firewall-cmd --permanent --add-port=$port --zone=public
        fi
     done;
     firewall-cmd --permanent --add-masquerade --zone=public
     firewall-cmd --reload
}

add_remove_iface_in_zones(){    
    local current_iface
    showmsg i "Remove interface from Public Zone:"
    current_iface=$(firewall-cmd --zone=public --list-interfaces) 

    for interface in $current_iface; do 
        firewall-cmd --permanent --zone=public --remove-interface="$interface"         
    done 
    # Apply changes to avoid error
    firewall-cmd --reload
    for zone_name in "${!zones[@]}"; do
        local interfaces="${zones[$zone_name]}"
        showmsg s "Adding interfaces '$interfaces' to zone '$zone_name'..."
        for interface in $interfaces; do
            firewall-cmd --permanent --zone="$zone_name" --add-interface="$interface" 
            showmsg s "Added interface '$interface' to zone '$zone_name'."
        done
        firewall-cmd --reload       
    done  
    firewall-cmd --reload
    showmsg s "Firewall reloaded and changes applied."
}

create_fw_policy(){      
    local target 
    showmsg i "Applying custom accept policies based on rules array..."
    for rule in "${firewall_policies[@]}"; do
        read -r src_zone dst_zone action <<< "$rule"
        policy_name="${src_zone}_to_${dst_zone}_a"        
        case "$action" in
            accept) target="ACCEPT" ;;
            drop) target="DROP" ;;
        esac

        if ! firewall-cmd --get-policies | grep -q "$policy_name"; then
            showmsg s "Creating policy $policy_name: $src_zone -> $dst_zone $target"
            firewall-cmd --permanent --new-policy="$policy_name" && \
            firewall-cmd --permanent --policy="$policy_name" --add-ingress-zone="$src_zone" && \
            firewall-cmd --permanent --policy="$policy_name" --add-egress-zone="$dst_zone" && \
            firewall-cmd --permanent --policy="$policy_name" --set-target="$target"
        else
            showmsg s "Policy $policy_name already exists, skipping creation."
        fi
    done
    firewall-cmd --reload
    showmsg s "Policies applied successfully."
}
create_direct_fw_rules(){
    showmsg i "Setting up direct firewall rules"
    local lan_interface
    local wan_interface
    local ports
    local port
    local protocol
    local priority=0  # Start with priority 4 for first rule
    for key in "${!firewall_direct_rules[@]}"; do
        source_if=$(echo "$key" | awk '{print $1}')
        dest_if=$(echo "$key" | awk '{print $2}')
        ports="${firewall_direct_rules[$key]}"
         # Add DNS rule for LAN to WAN direction
        firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD $priority -i "$source_if" -o "$dest_if" -p udp --dport 53 -j ACCEPT && \
        firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD $priority -i "$source_if" -o "$dest_if" -p icmp -j ACCEPT && \
        firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD $priority -i "$dest_if" -o "$source_if" -p icmp -j ACCEPT        
        for port_proto in $ports; do            
            port=$(echo "$port_proto" | cut -d'/' -f1)
            protocol=$(echo "$port_proto" | cut -d'/' -f2)
            firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 0 -i "$source_if" -o "$dest_if" -p "$protocol" --dport "$port" -j ACCEPT            
        done
         firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD $priority -i "$dest_if" -o "$source_if" -m state --state RELATED,ESTABLISHED -j ACCEPT && \
        firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD $priority -i "$source_if" -o "$dest_if" -j DROP
    done
    firewall-cmd --reload
    showmsg i "Firewall rules added and reloaded."
}
get_fw_details_debug(){    
    # Firewall running status
    if systemctl is-active --quiet firewalld; then
        showmsg s "Firewalld service is running."
    else
        showmsg e "Firewalld service is not running."
    fi
    # Firewall policies name
    showmsg s "Policies:"
    policies=$(firewall-cmd --get-policies)
    i=1
    for policy in $policies; do
        echo "$i.) $policy"
        ((i++))
    done
    # All active zone
    showmsg s "Active Zones:"
    active_zones=$(firewall-cmd --get-active-zones | awk 'NR % 2 == 1')
    i=1
    if [ -n "$active_zones" ]; then
        for zone in $active_zones; do        
            target=$(firewall-cmd --info-zone="$zone" | grep "target" | awk '{print $2}')
            interfaces=$(firewall-cmd --info-zone="$zone" | grep "interfaces" | awk -F': ' '{print $2}' | tr '\n' ', ' | sed 's/, $//')
            echo "$i.) Zone: $zone | Target: $target | Interfaces: $interfaces"
            ((i++))
        done
    else
        echo "No active zones found."
    fi
    # Firewal direct rules
    showmsg s "Direct rules:"   
    direct_rules=$(firewall-cmd --direct --get-all-rules)
    i=1
    if [ -n "$direct_rules" ]; then
        while IFS= read -r rule; do
            echo "$i.) $rule"
            ((i++))
        done <<< "$direct_rules"
    else
        echo "No direct rules found."
    fi
}
get_tun_status_ping_debug(){
    showmsg s "Running Wiregarud Tunnels are"
    wg | grep "interface"
    showmsg s "Tunnels status are"
    for waniface in "${wantun[@]}"; do        
        wan_ip=$(get_wireguard_info "$waniface" "ip")
        level="GW" 
        ip_parts=($(echo $wan_ip | tr '.' ' '))
        count=0        
        while true; do            
            current_ip="${ip_parts[0]}.${ip_parts[1]}.${ip_parts[2]}.$((ip_parts[3] + count))"
            if ping -c 1 -W 1 "$current_ip" &> /dev/null; then                
                if [ $count -gt 0 ]; then
                    level="${level}-->$waniface-Level$((count))"
                fi                
                ((count++))
            else
                echo -e "Tunnel $waniface connected up to Level $count: ${GREEN}$level${NC}"
                break
            fi
        done
    done

}
start_gw() {
  #showmsg "We are $1 gateway, please wait...."
  reset_gw $1
  check_system_details
  showmsg "Setting up started after refresh gateway"
  create_zones_with_default_settings
  add_remove_iface_in_zones
  check_active_internet_interfaces
  manage_wireguard up
  showmsg "Setting up routing for tunnels"
  setting_up_routing_lan_secure_tunnel
  setting_up_routing_wan_secure_tunnel   
  showmsg "Setting up firewall for gateway"
  create_fw_policy
  create_direct_fw_rules
  add_default_route  
  showmsg "Current State of gateway"
  get_fw_details_debug
  check_system_details
  get_tun_status_ping_debug 
}
# reset
reset_gw() {
  showmsg "We are $1 gateway, please wait...." 
  manage_wireguard down   
  reset_fw
  clear_ip_rules_and_flush_tables  
  start_stop_networkmanager  
}
# Debug 
debug_gw() {
  showmsg "We are $1 gateway, please wait...."  
  get_fw_details_debug
  check_system_details
  get_tun_status_ping_debug 
}
# Controller script
control_script() {
    help
    case "$1" in
        "1" | "2")   
            local user_input
            if [ "$1" == "1" ]; then
                user_input="starting"
            elif [ "$1" == "2" ]; then
                user_input="restarting"
            fi         
            start_gw "$user_input" 
            showmsg i "Gateway $user_input process is complete"            
            ;;
        "3" | "4")   
            local user_input
            if [ "$1" == "3" ]; then
                user_input="stopping"
            elif [ "$1" == "4" ]; then
                user_input="resetting"
            fi         
            reset_gw "$user_input"  
            check_system_details 
            showmsg i "Gateway is now at reset state"        
            ;;
        "5")                  
            debug_gw "Debugging"
            showmsg i "Gateway debugging is finished"
            ;;
        *)
            showmsg e "Invalid argument '$1'. Exiting script."
            kill $TOP_PID
            ;;
    esac
}

# Check if arguments were passed
if [ "$#" -lt 1 ]; then    
    help
    read -p "Your choice: " user_input
    if [ "$user_input" = "0" ]; then
        showmsg e "Exiting script..."
        exit 0
    fi    
    control_script "$user_input"
else    
    control_script "$1"
fi