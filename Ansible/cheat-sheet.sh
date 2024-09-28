HGet$^%2@826lkSrWNbdFg2#%
sed '/^\s*[#;]/d; /^\s*$/d' sudoers > sudoers.cleaned

#---------------------------------------------
# File Send or Recv
#---------------------------------------------
# Reciver
sudo nc -l 80 > cred.txt < /dev/null
# sender
nc -w 2 192.168.10.187 80 < vps_info.txt
cat openvpn.tar | netcat 192.168.1.1 8080

scp -oProtocol=2 -i ./ansible/playbook/ssh/files/infra -P 1179 infra@80.209.227.207:/etc/httpd/conf.d/vhost.conf .

#---------------------------------------------
# Ansible 
#---------------------------------------------

# Basic options
-vvv > output.log 2>&1 # for debug
2>&1 | grep -A 20 'PLAY RECAP' > output_file.txt output of script


#--------------------------------------------
# Initial VPS Steps
#--------------------------------------------
# Step 1. copy and paste ip port rootpass in vps_info.txt & run this command
./createinventory.py

# Step 2. 
#	a) Open ssh-pb add/remove roles
#	b) Change username if required default is hunter
#	c) Change key macthed key for the user as per desk
#	d) Run this command 
sudo ansible-playbook ssh-pb.yml -i hosts.ini --extra-vars "my_hosts=allvps" --ask-vault-pass 

# Step 3 (Optional)
# After configuration we need to use infra user as admin to change in vps if required
sudo ansible-playbook ssh-pb.yml -i hosts.ini --extra-vars "my_hosts=allvps login_user_name=infra" --ask-vault-pass 

# Custom Script with infra
# after configuration


#--------------------------------------------
# Direct Run Playbook
#--------------------------------------------
## Check ssh config daily to validate if every thing is working
ansible-playbook check-ssh-config.yml -i hosts.ini --extra-vars "my_hosts=allvps ansible_private_key_file=./ssh/files/infra ansible_user=infra" --ask-vault-pass 

## If want to replace cssh config file use this command before run change change_config_file: true default is false
ansible-playbook check-ssh-config.yml -i hosts.ini --extra-vars "my_hosts=allvps ansible_private_key_file=./ssh/files/infra ansible_user=infra change_config_file=true" --ask-vault-pass 

## Replace config file any
ansible-playbook replaceconf.yml -i hosts.ini --extra-vars "my_hosts=allvps ansible_private_key_file=./ssh/files/infra ansible_user=infra" --ask-vault-pass

## Change password & Key of selected User
ansible-playbook changePass.yml -i hosts.ini --extra-vars "my_hosts=allvps ansible_private_key_file=./ssh/files/infra ansible_user=infra" --ask-vault-pass

## Check service running of VPS
ansible-playbook checkservice.yml -i hosts.ini --extra-vars "my_hosts=allvps ansible_private_key_file=./ssh/files/infra ansible_user=infra" --ask-vault-pass

## CheckopenVPN
ansible-playbook checkopenvp.yml -i hosts.ini --extra-vars "my_hosts=allvps ansible_private_key_file=./ssh/files/infra ansible_user=infra" --ask-vault-pass
#--------------------------------------------
# Generate and Upload keys
#--------------------------------------------
ssh-keygen -t ed25519 -f "./files/pay" -N "" -C "paykey"

# For manual
ssh-keygen -t ed25519 -N "" -C "rsynckey"
ssh-copy-id -i ~/.ssh/id_ed25519.pub hunter@212.24.104.168 -p22

#--------------------------------------------
# Other Commands
#--------------------------------------------
# With root
ssh root@185.56.137.104 -p 7119 'sudo bash -s' < /path/to/local/script.sh

# Non root user command
ssh -tt hunter@178.63.172.28 -i ../../../../X-Ray/Infra/ansible/playbook/ssh/files/infra 'sudo wg'
# Run Script
(echo "dUG!6Mn5zt5i__C_"; cat install-wireguard-c7.sh) | ssh hunter@hunter@84.252.95.249 "sudo -Sp '' bash -s"


#--------------------------------------------
# Apache configuration for Operation
#--------------------------------------------
sudo mkdir -p /home/hunter/data && \
sudo mkdir -p /home/hunter/apache/www/default && \
sudo mkdir -p /home/hunter/apache/logs && \
sudo mkdir -p /home/hunter/apache/conf.d && \
sudo chown -R hunter:apache /home/hunter/data && \
sudo chown -R hunter:apache /home/hunter/apache && \
#sudo chmod g+s /home/hunter/data && \
#sudo chmod g+s /home/hunter/apache && \
sudo chmod 2660 /home/hunter/data && \
sudo chmod 2660 /home/hunter/apache && \
#sudo chmod 750 /home/hunter && \
#sudo chmod 775 /home/hunter/data && \
sudo usermod -a -G apache hunter && \
sudo usermod -a -G hunter apache && \
sudo setsebool -P httpd_unified 1 && \
sudo setsebool -P httpd_enable_homedirs true &&\
sudo semanage fcontext -a -t httpd_sys_rw_content_t '/home/hunter/data(/.*)?' &&\
sudo semanage fcontext -a -t httpd_log_t "/home/hunter/data/html/log(/.*)?" &&\
sudo restorecon -Rv /home/hunter/data && \
sudo restorecon -Rv /home/hunter/apache

#---------------------------------------------
# For apache home directory
#---------------------------------------------

sudo semanage fcontext -a -t httpd_sys_content_t "/home/hunter/data/html(/.*)?"
sudo semanage fcontext -a -t httpd_log_t "/home/hunter/data/log(/.*)?"
sudo restorecon -Rv /home/html/data

#---------------------------------------------
# Cron Job Entries of uploader and Rysnc server
#---------------------------------------------
# Delete empty folder place this on uploader with apache VPS
*/5 * * * * /usr/bin/find /home/hunter/data/* -type d -empty -delete
*/1 * * * * mkdir -p /home/hunter/data; chown -Rf hunter.apache /home/hunter/data; chmod -Rf 775 /home/hunter/data


# Validate rsync on Iland VPS
*/5 * * * * /usr/bin/find /home/hunter/data/* -type d -empty -delete; mkdir -p /home/hunter/data;
*/2 * * * * rsync -avzhP -e 'ssh' --remove-source-files hunter@212.24.104.168:/home/hunter/data/ /home/hunter/data/


#! Important in php file
# Data directory permission in php
770 or 755


#---------------------------------------------
# Firewall Cmds
#---------------------------------------------
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --permanent --add-service=ssh
firewall-cmd --permanent --add-port=7119/tcp
firewall-cmd --reload

#---------------------------------------------
# Sudoers Entry for hunter
#---------------------------------------------
hunter ALL=(ALL) NOPASSWD: /usr/bin/nc *
hunter ALL=(ALL) NOPASSWD: /bin/systemctl *
hunter ALL=(ALL) NOPASSWD: /usr/bin/firewall-cmd *
hunter ALL=(ALL) NOPASSWD: /usr/bin/tail * /var/log/*


hunter ALL=(ALL) NOPASSWD: /bin/cat /var/log/*
hunter ALL=(ALL) NOPASSWD: /bin/less /var/log/*
hunter ALL=(ALL) NOPASSWD: /usr/bin/grep /var/log/*


#---------------------------------------------
# Wire Guard
#---------------------------------------------

# For Client********************************************##
mkdir -p /etc/wireguard && \
touch /etc/wireguard/wg0.conf && \
firewall-cmd --zone=public --add-masquerade --permanent && \
firewall-cmd --zone=public --permanent --add-port=443/udp && \
firewall-cmd --reload

echo "net.ipv4.ip_forward = 1" | tee -a /etc/sysctl.conf && \
sysctl -p
nmcli con import type wireguard file /etc/wireguard/wg0.conf
##*********************************************************##

# alias
alias wgdown='wg-quick down wg0'
alias wgup='wg-quick up wg0'
source ~/.bashrc

# Add in network manager file
nmcli con import type wireguard file /etc/wireguard/wg0.conf

#port open then
# Optional
firewall-cmd --add-interface=wg0 --zone=public && \

firewall-cmd --zone=public --add-masquerade --permanent && \
firewall-cmd --zone=public --permanent --add-port=443/udp && \
firewall-cmd --reload

firewall-cmd --zone=public --remove-masquerade --permanent
firewall-cmd --zone=public --remove-masquerade

# Using Iptable
# Check masquerade
sudo iptables -L -v -n

sudo iptables -t nat -L POSTROUTING -v -n
# If not use this command to verifiy
sudo iptables -t nat -A POSTROUTING -o wg0 -j MASQUERADE && \
sudo ip6tables -t nat -A POSTROUTING -o wg0 -j MASQUERADE 
# Port
sudo iptables -A INPUT -p udp --dport 443 -j ACCEPT
sudo iptables -A INPUT -p udp --sport 443 -j ACCEPT

#Centos9 nftable
sudo nft list ruleset




sudo ip route add 17.16.0.0/24 dev wg0


# Other

sudo /sbin/ip route add default dev wg0 table 123

sudo /sbin/ip rule add from 172.16.0.0/24 table 123
sudo /sbin/iptables -t nat -A POSTROUTING -o wg0 -j MASQUERADE
sudo /sbin/iptables -t nat -A POSTROUTING -o enp0s8 -j MASQUERADE

PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o enp1s0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o enp1s0 -j MASQUERADE
L
# Debug
ip route show
sudo firewall-cmd --get-zones
sudo firewall-cmd --get-active-zones
sudo firewall-cmd --zone=public --list-all
sudo firewall-cmd --permanent --new-zone=myzone
#Port fwd
sudo firewall-cmd --zone=public --remove-forward-port=port=443:proto=udp:toport=443:toaddr= --permanent
#---------------------------------------------
# Wire Guard Ends
#---------------------------------------------