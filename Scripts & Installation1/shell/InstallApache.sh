#!/bin/bash

# Define colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Add commonly used paths to PATH variable
PATH=$PATH:/bin:/usr/bin:/usr/sbin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export PATH

# Function to display installation banner
DisplayBanner() {
  echo -e "${GREEN}############################################################${NC}"
  echo -e "${GREEN}#                  Apache Installation in Centos8          #${NC}"
  echo -e "${GREEN}############################################################${NC}"
  echo -e "${YELLOW}This script will install and configure apache webserver.   ${NC}"
  echo -e "${YELLOW}Please follow the prompts to proceed.${NC}"
  echo ""
}
InstallApache() {

  # Prompt user for Nginx machine IP address or domain name
  read -p "Enter Domain name of website: " DOMAIN
  while [[ -z "$DOMAIN" ]]; do
    read -p "Enter Domain name of website: " DOMAIN
  done

}
DisplayBanner
InstallApache
