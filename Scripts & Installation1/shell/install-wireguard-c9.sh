#!/bin/bash


# With Root user
# ssh infra@54.38.212.180 -p 7119 -i ../../ansible/playbook/ssh/files/infra 'sudo bash -s' < install-wireguard-c7.sh 
# Or
# (echo ")BMm)KK49(FxU(44"; cat install-wireguard-c7.sh) | ssh infra@54.38.212.180 -p 7119 -i  "sudo -Sp '' bash -s"
# Or
# (echo "dUG!6Mn5zt5i__C_"; cat install-wireguard-c7.sh) | ssh -tt hunter@hunter@84.252.95.249 "sudo bash -s"

# Color Codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Banner
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}      WireGuard Installation Script      ${NC}"
echo -e "${GREEN}                Centos 9     			  ${NC}"
echo -e "${GREEN}=========================================${NC}"

# Step 1: Update package repository and install necessary packages
echo -e "${YELLOW}Installing wiregurad tools and firewalld...${NC}"
sudo dnf update -y
echo -e "${YELLOW}Installing epel-release and elrepo-release...${NC}"
sudo dnf install epel-release elrepo-release -y
echo -e "${GREEN}Done!${NC}"


# # Step 2: Install epel-release and elrepo-release
echo -e "${YELLOW}Installing wiregurad tools...${NC}"
sudo dnf install wireguard-tools -y
echo -e "${GREEN}Done!${NC}"

# # Step 3: Enable CentOS Plus repository and include kernel-plus packages
# echo -e "${YELLOW}Configuring CentOS Plus repository...${NC}"
# # sudo yum-config-manager --setopt=centosplus.includepkgs=kernel-plus --enablerepo=centosplus --save
# sudo yum-config-manager --setopt=centosplus.includepkgs=kernel-plus --enablerepo=centosplus --save > /dev/null 2>&1
# echo -e "${GREEN}Done!${NC}"

# # Step 4: Set default kernel to kernel-plus
# echo -e "${YELLOW}Setting default kernel to kernel-plus...${NC}"
# sudo sed -e 's/^DEFAULTKERNEL=kernel$/DEFAULTKERNEL=kernel-plus/' -i /etc/sysconfig/kernel
# echo -e "${GREEN}Done!${NC}"

# # Step 5: Install kernel-plus and WireGuard tools
# echo -e "${YELLOW}Installing kernel-plus and WireGuard tools...${NC}"
# sudo yum install -y kernel-plus wireguard-tools
# echo -e "${GREEN}Done!${NC}"

# Step 6: Configure firewall rules for WireGuard
echo -e "${YELLOW}Configuring firewall rules...${NC}"
sudo firewall-cmd --permanent --add-port=443/udp
echo -e "${GREEN}443 Port added${NC}"
sudo firewall-cmd --zone=public --permanent --add-masquerade
echo -e "${GREEN}masquerade done!${NC}"
sudo firewall-cmd --reload
echo -e "${GREEN}Firewall rules Done!${NC}"

# Step 7: Enable IP forwarding
echo -e "${YELLOW}Enabling IP forwarding...${NC}"
sudo echo "net.ipv4.ip_forward = 1" | tee -a /etc/sysctl.conf
sudo sysctl -p
echo -e "${GREEN}Done!${NC}"

# Step 8: Create WireGuard directory and configuration file
echo -e "${YELLOW}Creating WireGuard directory and configuration file...${NC}"
sudo mkdir -p /etc/wireguard/
sudo touch /etc/wireguard/wg0.conf
echo -e "${GREEN}Done!${NC}"
echo -e "${GREEN}Congratulation we have successfully installed wireguard!${NC}"
# Step 9: Reboot the system to apply changes
echo -e "${RED}Rebooting the system to apply changes...${NC}"
sudo reboot
