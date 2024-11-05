#!/bin/bash

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root.${NC}" 
   exit 1
fi

# Function to display a banner
banner() {
    echo -e "${BLUE}=========================================${NC}"
    echo -e "${GREEN}         Secure SSH Version 1.2         ${NC}"
    echo -e "${BLUE}=========================================${NC}"
}

# Common setup steps for both Ubuntu versions
common_setup() {
    # Remove existing SSH host keys
    echo -e "${YELLOW}Removing existing SSH host keys...${NC}"
    rm -f /etc/ssh/ssh_host_*

    # Generate new SSH host keys
    echo -e "${YELLOW}Generating new SSH host keys...${NC}"
    ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key -N ""
    ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ""

    # Update sshd_config with new HostKey entries
    echo -e "\nHostKey /etc/ssh/ssh_host_ed25519_key\nHostKey /etc/ssh/ssh_host_rsa_key" >> /etc/ssh/sshd_config

    # Update moduli file
    awk '$5 >= 3071' /etc/ssh/moduli > /etc/ssh/moduli.safe
    mv /etc/ssh/moduli.safe /etc/ssh/moduli
}

# Function to check if the OS is Ubuntu 22.04 or 24.04
check_os_version() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        if [[ "$NAME" == "Ubuntu" && "$VERSION_ID" == "24.04" ]]; then
            echo -e "${GREEN}Ubuntu 24.04 LTS detected. Running configuration for Ubuntu 24.04...${NC}"
            configure_ubuntu_24
        elif [[ "$NAME" == "Ubuntu" && "$VERSION_ID" == "22.04" ]]; then
            echo -e "${GREEN}Ubuntu 22.04 LTS detected. Running configuration for Ubuntu 22.04...${NC}"
            configure_ubuntu_22
        else
            echo -e "${RED}This script is intended for Ubuntu 22.04 or 24.04 only. Exiting.${NC}"
            exit 1
        fi
    else
        echo -e "${RED}/etc/os-release file not found. Cannot determine OS version. Exiting.${NC}"
        exit 1
    fi
}

# Function to configure settings for Ubuntu 24.04
configure_ubuntu_24() {

    common_setup

    cat <<EOT > /etc/ssh/sshd_config.d/ssh-audit_hardening.conf
# SSH hardening configuration for Ubuntu 24.04
KexAlgorithms sntrup761x25519-sha512@openssh.com,gss-curve25519-sha256-,curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group18-sha512,diffie-hellman-group-exchange-sha256,gss-group16-sha512-,diffie-hellman-group16-sha512
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-gcm@openssh.com,aes128-ctr
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com
RequiredRSASize 3072
HostKeyAlgorithms sk-ssh-ed25519-cert-v01@openssh.com,ssh-ed25519-cert-v01@openssh.com,rsa-sha2-512-cert-v01@openssh.com,rsa-sha2-256-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com,ssh-ed25519,rsa-sha2-512,rsa-sha2-256
CASignatureAlgorithms sk-ssh-ed25519@openssh.com,ssh-ed25519,rsa-sha2-512,rsa-sha2-256
GSSAPIKexAlgorithms gss-curve25519-sha256-,gss-group16-sha512-
HostbasedAcceptedAlgorithms sk-ssh-ed25519-cert-v01@openssh.com,ssh-ed25519-cert-v01@openssh.com,rsa-sha2-512-cert-v01@openssh.com,rsa-sha2-256-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com,ssh-ed25519,rsa-sha2-512,rsa-sha2-256
PubkeyAcceptedAlgorithms sk-ssh-ed25519-cert-v01@openssh.com,ssh-ed25519-cert-v01@openssh.com,rsa-sha2-512-cert-v01@openssh.com,rsa-sha2-256-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com,ssh-ed25519,rsa-sha2-512,rsa-sha2-256
EOT

}

# Function to configure settings for Ubuntu 22.04
configure_ubuntu_22() {
    common_setup

    cat <<EOT > /etc/ssh/sshd_config.d/ssh-audit_hardening.conf
# SSH hardening configuration for Ubuntu 22.04
KexAlgorithms sntrup761x25519-sha512@openssh.com,curve25519-sha256,curve25519-sha256@libssh.org,gss-curve25519-sha256-,diffie-hellman-group16-sha512,gss-group16-sha512-,diffie-hellman-group18-sha512,diffie-hellman-group-exchange-sha256
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-gcm@openssh.com,aes128-ctr
MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,umac-128-etm@openssh.com
HostKeyAlgorithms sk-ssh-ed25519-cert-v01@openssh.com,ssh-ed25519-cert-v01@openssh.com,rsa-sha2-512-cert-v01@openssh.com,rsa-sha2-256-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com,ssh-ed25519,rsa-sha2-512,rsa-sha2-256
CASignatureAlgorithms sk-ssh-ed25519@openssh.com,ssh-ed25519,rsa-sha2-512,rsa-sha2-256
GSSAPIKexAlgorithms gss-curve25519-sha256-,gss-group16-sha512-
HostbasedAcceptedAlgorithms sk-ssh-ed25519-cert-v01@openssh.com,ssh-ed25519-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com,ssh-ed25519,rsa-sha2-512-cert-v01@openssh.com,rsa-sha2-512,rsa-sha2-256-cert-v01@openssh.com,rsa-sha2-256
PubkeyAcceptedAlgorithms sk-ssh-ed25519-cert-v01@openssh.com,ssh-ed25519-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com,ssh-ed25519,rsa-sha2-512-cert-v01@openssh.com,rsa-sha2-512,rsa-sha2-256-cert-v01@openssh.com,rsa-sha2-256
EOT

}

# Display the banner
banner

# Run the OS check
check_os_version

# Restart Service
echo -e "${YELLOW}Restarting SSH service...${NC}"
service ssh restart
