sudo yum install wireguard-tools net-tools git python3.11 -y && \
git clone https://github.com/donaldzou/WGDashboard.git && \
cd ./WGDashboard/src && \
chmod +x ./wgd.sh && \
./wgd.sh install && \
sudo echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf && \
sudo sysctl -p /etc/sysctl.conf && \
firewall-cmd --add-port=10086/tcp --permanent && \
firewall-cmd --add-port=51820/udp --permanent && \
firewall-cmd --reload
