#!/bin/bash

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Banner
echo -e "${BLUE}*************************************${NC}"
echo -e "${GREEN}         Start Gateway              ${NC}"
echo -e "${BLUE}*************************************${NC}"


# sudo iptables -F
# sudo iptables -X
# sudo iptables -F -t nat
# sudo iptables -P INPUT ACCEPT
# sudo iptables -P FORWARD ACCEPT
# sudo iptables -P OUTPUT ACCEPT
# sudo service iptables save
# systemctl restart iptables


add_pay_route() {

    PAYMENTROUTE="206 pmtroute"
    PAYMENT_INTERFACE="pmt"
    EXIT_INTERFACE="tun0"

    # Bring up WireGuard interfaces if not already up
    for intf in "${EXIT_INTERFACE}" "${PAYMENT_INTERFACE}"; do
        if ! wg show "${intf}" > /dev/null 2>&1; then
            echo -e "${CYAN}Starting WireGuard interface ${intf}...${NC}"
            if ! wg-quick up "${intf}"; then
                echo -e "${RED}Failed to bring up WireGuard interface ${intf}. Exiting...${NC}"
                exit 1
            fi
            echo -e "${GREEN}WireGuard interface ${intf} is up!${NC}"
        else
            echo -e "${GREEN}WireGuard interface ${intf} is already up. Ignoring...${NC}"
        fi
    done

    echo -e "${CYAN}Adding payment route...${NC}"
    TABLE_NAME="${PAYMENTROUTE#* }"

    if ! grep -q "${PAYMENTROUTE}" /etc/iproute2/rt_tables; then
        echo -e "${YELLOW}Creating route table ${PAYMENTROUTE}...${NC}"
        echo "${PAYMENTROUTE}" >> /etc/iproute2/rt_tables || {
            echo -e "${RED}Failed to create route table. Exiting...${NC}"
            exit 1
        }
    else
        echo -e "${GREEN}Route table ${PAYMENTROUTE} already exists. Ignoring...${NC}"
    fi

    echo -e "${CYAN}Configuring iptables for payment route...${NC}"
    iptables -t nat -A POSTROUTING -o "${EXIT_INTERFACE}" -j MASQUERADE || {
        echo -e "${RED}Failed to configure iptables. Exiting...${NC}"
        exit 1
    }
    
    echo -e "${CYAN}Adding routing rules for payment route...${NC}"
    /sbin/ip rule add from 10.20.0.0/24 table "${TABLE_NAME}" || {
        echo -e "${RED}Failed to add routing rule. Exiting...${NC}"
        exit 1
    }
    /sbin/ip route add default via 172.16.0.1 dev "${EXIT_INTERFACE}" table "${TABLE_NAME}" || {
        echo -e "${RED}Failed to add route. Exiting...${NC}"
        exit 1
    }

    echo -e "${GREEN}Payment route setup complete!${NC}"

}

add_pay_route






# add_iptablerules_pmt_tun0_old() {
   
#     echo -e "${YELLOW}Open port from pmt to tun0...${NC}"

#     # Allow specific ports from pmt to tun0
#     iptables -I FORWARD 1 -i pmt -o tun0 -p udp --dport 53 -j ACCEPT; 
#     iptables -I FORWARD 2 -i pmt -o tun0 -p tcp --dport 53 -j ACCEPT; 
#     iptables -I FORWARD 3 -i pmt -o tun0 -p tcp --dport 443 -j ACCEPT;
#     iptables -I FORWARD 4 -i pmt -o tun0 -p udp --dport 443 -j ACCEPT;
#     iptables -I FORWARD 5 -i pmt -o tun0 -p tcp --dport 22 -j ACCEPT;
#     iptables -I FORWARD 6 -i pmt -o tun0 -p tcp --dport 1179 -j ACCEPT;
#     iptables -I FORWARD 7 -i pmt -o tun0 -p tcp --dport 7119 -j ACCEPT;
#     iptables -I FORWARD 8 -i pmt -o tun0 -p icmp -j ACCEPT;
#     iptables -I FORWARD 9 -i pmt -o tun0 -j DROP; 
#     iptables -A FORWARD -i tun0 -o pmt -m state --state RELATED,ESTABLISHED -j ACCEPT;
# }


# add_iptablerules_pmt_tun0() {
   
#     echo -e "${YELLOW}Open port from pmt to tun0...${NC}"

#     # Allow specific ports from pmt to tun0  
#     sudo iptables -P OUTPUT DROP
#     sudo iptables -I OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
#     sudo iptables -I OUTPUT -o tun0 -p udp --dport 53 -j ACCEPT
#     sudo iptables -I OUTPUT -o tun0 -p tcp --dport 53 -j ACCEPT
#     sudo iptables -I OUTPUT -o tun0 -p tcp --dport 443 -j ACCEPT
#     sudo iptables -I OUTPUT -o tun0 -p udp --dport 443 -j ACCEPT
#     sudo iptables -I OUTPUT -o tun0 -p tcp --dport 80 -j ACCEPT
#     sudo iptables -I OUTPUT -o tun0 -p tcp --dport 7119 -j ACCEPT
#     sudo iptables -I OUTPUT -o tun0 -p tcp --dport 1179 -j ACCEPT
#     sudo iptables -I OUTPUT -o tun0 -p tcp --dport 51820 -j ACCEPT
#     sudo iptables -I OUTPUT -o tun0 -p tcp --dport 22 -j ACCEPT
#     sudo iptables -I OUTPUT -o tun0 -p icmp -j ACCEPT
#     sudo iptables -I OUTPUT -o tun0 -j DROP; 
#     sudo iptables -I INPUT -m state --state ESTABLISHED -j ACCEPT

# }


# block_traffic_enp5s0_external() {
   
#     echo -e "${YELLOW}Block all port on enp5s0 except wirequard...${NC}"
#     sudo iptables -P OUTPUT DROP
#     sudo iptables -A OUTPUT -m state --state ESTABLISHED -j ACCEPT

#     # Allow specific ports from pmt to tun0
#     iptables -A INPUT -i enp5s0 -p tcp --dport 443 -j ACCEPT
#     iptables -A INPUT -i enp5s0 -p tcp --dport 80 -j ACCEPT
#     iptables -A INPUT -i enp5s0 -p tcp --dport 22 -j ACCEPT
#     iptables -A INPUT -i enp5s0 -p tcp --dport 1179 -j ACCEPT
#     iptables -A INPUT -i enp5s0 -p tcp --dport 7119 -j ACCEPT
#     iptables -A INPUT -i enp5s0 -p udp --dport 443 -j ACCEPT
#     iptables -A INPUT -i enp5s0 -p udp --dport 51820 -j ACCEPT
#     iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
# }



# Call the function
# block_traffic_enp5s0_external

#add_iptablerules_pmt_tun0