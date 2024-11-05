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
    echo -e "${GREEN}        CentOS SSH Hardening 1.0       ${NC}"
    echo -e "${YELLOW}         Bytesec - Secure your SSH      ${NC}"
    echo -e "${BLUE}=========================================${NC}"
}

# Common setup steps for CentOS
common_setup() {
    # Remove existing SSH host keys
    echo -e "${YELLOW}Removing existing SSH host keys...${NC}"
    rm -f /etc/ssh/ssh_host_*

    # Generate new SSH host keys
    echo -e "${YELLOW}Generating new SSH host keys...${NC}"
    ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ""
    
    # Adjust permissions
    chgrp ssh_keys /etc/ssh/ssh_host_ed25519_key
    chmod g+r /etc/ssh/ssh_host_ed25519_key

    # Update moduli file
    echo -e "${YELLOW}Update moduli file with bigger key length...${NC}"
    awk '$5 >= 3071' /etc/ssh/moduli > /etc/ssh/moduli.safe
    mv -f /etc/ssh/moduli.safe /etc/ssh/moduli
}

# Function to configure settings for CentOS 7
configure_centos_7() {
    echo -e "${GREEN}Configuring SSH for CentOS 7...${NC}"

    # Create systemd service override directory and config
    mkdir -p /etc/systemd/system/sshd-keygen.service.d
    cat << EOF > /etc/systemd/system/sshd-keygen.service.d/ssh-audit.conf
[Unit]
ConditionFileNotEmpty=
ConditionFileNotEmpty=!/etc/ssh/ssh_host_ed25519_key
EOF

    systemctl daemon-reload

    # Call common setup
    common_setup

    # Restrict key exchange, cipher, and MAC algorithms
    echo -e "${YELLOW}Restricting algorithms in sshd_config...${NC}"
    sed -i 's/^HostKey \/etc\/ssh\/ssh_host_\(rsa\|dsa\|ecdsa\)_key$/\#HostKey \/etc\/ssh\/ssh_host_\1_key/g' /etc/ssh/sshd_config
    echo -e "\n# Restrict key exchange, cipher, and MAC algorithms, as per sshaudit.com\n# hardening guide.\nKexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group18-sha512,diffie-hellman-group16-sha512,diffie-hellman-group-exchange-sha256\nCiphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr\nMACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,umac-128-etm@openssh.com" >> /etc/ssh/sshd_config

}

# Function to configure settings for CentOS 9
configure_centos_9() {
    echo -e "${GREEN}Configuring SSH for CentOS 9...${NC}"

    # Call common setup
    common_setup

    # Additional SSH host key generation for RSA
    ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key -N ""
    
    # Adjust permissions for both keys
    chgrp ssh_keys /etc/ssh/ssh_host_rsa_key /etc/ssh/ssh_host_ed25519_key
    chmod g+r /etc/ssh/ssh_host_rsa_key /etc/ssh/ssh_host_ed25519_key

    # Restrict HostKey entry for ecdsa
    sed -i 's/^HostKey \/etc\/ssh\/ssh_host_ecdsa_key$/\#HostKey \/etc\/ssh\/ssh_host_ecdsa_key/g' /etc/ssh/sshd_config

    # Backup and modify crypto policies for OpenSSH
    cp /etc/crypto-policies/back-ends/opensshserver.config /etc/crypto-policies/back-ends/opensshserver.config.orig
    echo -e "CRYPTO_POLICY='-oCiphers=chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr -oMACs=hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,umac-128-etm@openssh.com -oGSSAPIKexAlgorithms=gss-curve25519-sha256- -oKexAlgorithms=curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,diffie-hellman-group-exchange-sha256 -oHostKeyAlgorithms=ssh-ed25519,ssh-ed25519-cert-v01@openssh.com,rsa-sha2-256,rsa-sha2-512 -oPubkeyAcceptedKeyTypes=ssh-ed25519,ssh-ed25519-cert-v01@openssh.com,rsa-sha2-256,rsa-sha2-512'" > /etc/crypto-policies/back-ends/opensshserver.config

    
   
}

# Display the banner
banner

# Determine OS version and call the respective function
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    if [[ "$NAME" == "CentOS" && "$VERSION_ID" == "7" ]]; then
        configure_centos_7
    elif [[ "$NAME" == "CentOS" && "$VERSION_ID" == "9" ]]; then
        configure_centos_9
    else
        echo -e "${RED}This script is intended for CentOS 7 or 9 only. Exiting.${NC}"
        exit 1
    fi
else
    echo -e "${RED}/etc/os-release file not found. Cannot determine OS version. Exiting.${NC}"
    exit 1
fi

# Restart SSH service
echo -e "${YELLOW}Restarting SSH service...${NC}"
systemctl restart sshd.service
echo -e "${GREEN}SSH hardening process completed.${NC}"