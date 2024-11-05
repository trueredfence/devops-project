#!/bin/bash

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Function to check if the OS is Ubuntu 22.04 or 24.04
check_os_version() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        if [[ "$NAME" == "Ubuntu" && "$VERSION_ID" == "24.04" ]]; then
            echo "Ubuntu 24.04 LTS detected. Running configuration for Ubuntu 24.04..."
            configure_ubuntu_24
        elif [[ "$NAME" == "Ubuntu" && "$VERSION_ID" == "22.04" ]]; then
            echo "Ubuntu 22.04 LTS detected. Running configuration for Ubuntu 22.04..."
            configure_ubuntu_22
        else
            echo "This script is intended for Ubuntu 22.04 or 24.04 only. Exiting."
            exit 1
        fi
    else
        echo "/etc/os-release file not found. Cannot determine OS version. Exiting."
        exit 1
    fi
}

# Function to configure settings for Ubuntu 24.04
configure_ubuntu_24() {
    # Commands for Ubuntu 24.04 configuration
    rm /etc/ssh/ssh_host_*
    ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ""
    ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key -N ""
    awk '$5 >= 3071' /etc/ssh/moduli > /etc/ssh/moduli.safe
    mv /etc/ssh/moduli.safe /etc/ssh/moduli
    echo -e "\nHostKey /etc/ssh/ssh_host_ed25519_key\nHostKey /etc/ssh/ssh_host_rsa_key" >> /etc/ssh/sshd_config
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
    service ssh restart
    #iptables -I INPUT -p tcp --dport 22 -m state --state NEW -m recent --set
    #iptables -I INPUT -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 10 --hitcount 10 -j DROP
    #ip6tables -I INPUT -p tcp --dport 22 -m state --state NEW -m recent --set
    #ip6tables -I INPUT -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 10 --hitcount 10 -j DROP
    #DEBIAN_FRONTEND=noninteractive apt install -q -y netfilter-persistent iptables-persistent
    #service netfilter-persistent save
}

# Function to configure settings for Ubuntu 22.04
configure_ubuntu_22() {
    # Commands for Ubuntu 22.04 configuration
    rm /etc/ssh/ssh_host_*
    ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key -N ""
    ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ""
    echo -e "\nHostKey /etc/ssh/ssh_host_ed25519_key\nHostKey /etc/ssh/ssh_host_rsa_key" >> /etc/ssh/sshd_config
    awk '$5 >= 3071' /etc/ssh/moduli > /etc/ssh/moduli.safe
    mv /etc/ssh/moduli.safe /etc/ssh/moduli
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
    #iptables -I INPUT -p tcp --dport 22 -m state --state NEW -m recent --set
    #iptables -I INPUT -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 10 --hitcount 10 -j DROP
    #ip6tables -I INPUT -p tcp --dport 22 -m state --state NEW -m recent --set
    #ip6tables -I INPUT -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 10 --hitcount 10 -j DROP
    #DEBIAN_FRONTEND=noninteractive apt install -q -y netfilter-persistent iptables-persistent
    #service netfilter-persistent save
    service ssh restart
}

# Run the OS check
check_os_version
