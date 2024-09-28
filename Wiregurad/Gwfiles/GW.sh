#---------------------------------------------
# Packages
#---------------------------------------------
sudo dnf install cockpit wget util-linux-user wireguard-tools firewalld net-tools -y

# Install WGDashboard
sudo dnf install net-tools git python3.11 -y && \
cd /etc/ && \
git clone https://github.com/donaldzou/WGDashboard.git wgdashboard && \
cd ./wgdashboard/src && \
chmod +x ./wgd.sh && \
./wgd.sh install && \
firewall-cmd --zone=public --add-port=5000/tcp --permanent && \
firewall-cmd --reload

# Cockpit
https://192.168.10.1:9090/

# Wireguard
# Change config file of wgdashboard
http://192.168.10.1:5000

#---------------------------------------------
# Wireguard IP Range
#---------------------------------------------
172.16.10.* # For Direct wg0.conf
172.16.11.* # Secure 1 wg1.conf
172.16.12.* # Secure 2 wg2.conf
172.16.13.* # Secure 3 wg3.conf

#---------------------------------------------
# Shortcut and Services
#---------------------------------------------
echo "alias wg0down='sudo systemctl stop wg-quick@wg0'" >> ~/.zshrc
echo "alias wg0up='wg-quick up wg0'" >> ~/.zshrc
echo "alias wg1down='wg-quick down wg1'" >> ~/.zshrc
echo "alias wg1up='wg-quick up wg1'" >> ~/.zshrc
echo "alias wg2down='wg-quick down wg2'" >> ~/.zshrc
echo "alias wg2up='wg-quick up wg2'" >> ~/.zshrc
source ~/.zshrc


echo "alias wg0stop='sudo systemctl stop wg-quick@wg0'" >> ~/.zshrc
echo "alias wg0start='sudo systemctl start wg-quick@wg0'" >> ~/.zshrc
echo "alias wg1stop='sudo systemctl stop wg-quick@wg1'" >> ~/.zshrc
echo "alias wg1start='sudo systemctl start wg-quick@wg1'" >> ~/.zshrc
echo "alias wg2stop='sudo systemctl stop wg-quick@wg2'" >> ~/.zshrc
echo "alias wg2start='sudo systemctl start wg-quick@wg2'" >> ~/.zshrc

echo "alias wgstart='sudo systemctl start wg-quick@wg0 && sudo systemctl start wg-quick@wg1'" >> ~/.zshrc
echo "alias wgstop='sudo systemctl stop wg-quick@wg0 && sudo systemctl stop wg-quick@wg1'" >> ~/.zshrc
echo "alias wgrestart='sudo systemctl restart wg-quick@wg0 && sudo systemctl restart wg-quick@wg1'" >> ~/.zshrc
source ~/.zshrc




# Create and Enable service to start at startup

sudo systemctl enable wg-quick@wg0.service && \
sudo systemctl enable wg-quick@wg1.service && \
sudo systemctl daemon-reload && \
sudo systemctl start wg-quick@wg0 && \
sudo systemctl start wg-quick@wg1


#---------------------------------------------
# For Client
#---------------------------------------------

mkdir -p /etc/wireguard && \
touch /etc/wireguard/wg1.conf && \

# Optional If Firewall Error & Zone not mached
firewall-cmd --zone=public --add-masquerade --permanent && \
firewall-cmd --zone=public --permanent --add-port=51820/udp && \
firewall-cmd --zone=public --permanent --add-port=443/udp && \
firewall-cmd --reload

# Optional
firewall-cmd --zone=public --permanent  --add-interface=wg0

# Required 
echo "net.ipv4.ip_forward = 1" | tee -a /etc/sysctl.conf && \
sysctl -p

#---------------------------------------------
# NMCLI Command 
#---------------------------------------------

# For Client if DNS not working
sudo nmcli connection modify wg1 ipv4.dns "8.8.8.8 8.8.4.4 1.1.1.1"
sudo nmcli connection modify wg1 ipv4.dns-search ""
sudo nmcli connection modify wg1 ipv4.ignore-auto-dns yes
sudo systemctl restart NetworkManager


# For Direct
nmcli con import type wireguard file /etc/wireguard/wg0.conf
# For Secure
nmcli con import type wireguard file /etc/wireguard/wg1.conf
# For NAS
nmcli con import type wireguard file /etc/wireguard/wg1.conf

# Remove connectio if required
nmcli connection delete wg0

#---------------------------------------------
# For Gateway Firewall
#---------------------------------------------

# Basic Configuration
mkdir -p /etc/wireguard && \
touch /etc/wireguard/wg1.conf && \

firewall-cmd --zone=public --add-masquerade --permanent && \
firewall-cmd --zone=public --permanent --add-port=51820/udp && \
firewall-cmd --zone=public --permanent  --add-interface=wg0
firewall-cmd --reload

echo "net.ipv4.ip_forward = 1" | tee -a /etc/sysctl.conf && \
sysctl -p
