#!/bin/bash
# Usages ./nordvpn.sh Vietnam or ./nordvpn.sh logout

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Banner
echo -e "${BLUE}*************************************${NC}"
echo -e "${GREEN}   VPN Setup Script                 ${NC}"
echo -e "${BLUE}*************************************${NC}"

# Check if the route table already exists
if ! grep -q "206 tunroute" /etc/iproute2/rt_tables; then
    echo -e "${YELLOW}Creating route table 'tunroute'...${NC}"
    echo '206 tunroute' >> /etc/iproute2/rt_tables
else
    echo -e "${GREEN}Route table 'tunroute' already exists. Ignoring...${NC}"
fi

# Check for the argument
if [ "$1" == "logout" ]; then
    echo -e "${YELLOW}Logging out...${NC}"
    echo -e "${YELLOW}Bringing down WireGuard interface...${NC}"
    wg-quick down wg0
    
    echo -e "${YELLOW}Disconnecting from NordVPN...${NC}"
    nordvpn d
    
    echo -e "${YELLOW}Flushing NAT table...${NC}"
    iptables -t nat -F
    
    echo -e "${GREEN}Successfully logged out.${NC}"
    exit 0
fi

# Bring up WireGuard interface
echo -e "${YELLOW}Bringing up WireGuard interface...${NC}"
wg-quick up wg0

# Check for country name argument
if [ -z "$1" ]; then
    echo -e "${RED}Usage: $0 <countryname>${NC}"
    exit 1
fi

# Connect to NordVPN
echo -e "${YELLOW}Connecting to NordVPN in country: $1...${NC}"
nordvpn connect "$1"

# Add IP rule
echo -e "${YELLOW}Adding IP rule...${NC}"
ip rule add from 172.16.0.0/24 table tunroute

# Add route
echo -e "${YELLOW}Adding route...${NC}"
ip route add default via 10.5.0.2 dev nordlynx table tunroute

echo -e "${GREEN}VPN setup complete. You are connected to $1 ${NC}"
