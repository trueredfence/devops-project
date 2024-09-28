# Firewall Linux Centos 8

ip link show
nmcli device status

firewall-cmd --get-active-zones
firewall-cmd --zone=public --set-target=DROP --permanent
firewall-cmd --zone=public --add-port=3001/tcp --permanent
firewall-cmd --reload
firewall-cmd --list-all-zones
firewall-cmd --get-zones
firewall-cmd --get-default-zone

firewall-cmd --list-all
firewall-cmd --list-all --zone=public
firewall-cmd --list-services
firewall-cmd --list-services --zone=public
firewall-cmd --zone=internal --list-ports
firewall-cmd --permanent --zone=web --set-target=DROP
firewall-cmd --permanent --zone=web --add-service=icmp
firewall-cmd --zone=web --remove-interface=enp0s8 --permanent
firewall-cmd --zone=web --add-interface=enp0s8 --permanent

firewall-cmd --zone=public --add-forward-port=port=80:proto=tcp:toport=8080 --permanent

firewall-cmd --zone=public --add-masquerade
firewall-cmd --zone=public --add-forward-port=port=443:proto=tcp:toport=443:toaddr=192.168.2.42 --permanent

## Allow ssh from one ip only rich rule

firewall-cmd --permanent --zone=public --add-rich-rule 'rule family="ipv4" source address="10.8.0.8" port port=22 protocol=tcp accept'
firewall-cmd --list-rich-rules --permanent

## remove rich rule

firewall-cmd --remove-rich-rule 'rule family="ipv4" source address="10.8.0.8" port port=22 protocol=tcp accept' --permanent

nginx
firewall-cmd --zone=public --add-service=http --add-service=https --permanent
firewall-cmd --reload

Gateway
sysctl -w net.ipv4.ip_forward=1
firewall-cmd --zone=public --add-masquerade --permanent
firewall-cmd --reload

Application
ip route add default via 192.168.56.103
echo GATEWAY=192.168.56.103 >> /etc/sysconfig/network-scripts/ifcfg-enp0s8

WebApplicaton
firewall-cmd --permanent --new-zone=web &&
firewall-cmd --permanent --zone=web --add-service=http &&
firewall-cmd --permanent --zone=web --add-service=https &&
firewall-cmd --permanent --zone=public --add-source=192.168.56.103 &&
firewall-cmd --permanent --zone=public --add-service=ssh &&
firewall-cmd --permanent --zone=web --add-interface=enp0s8
firewall-cmd --reload

## Keep Alive Nginx

dnf install keepalived
ip add show
firewall-cmd --add-rich-rule='rule protocol value="vrrp" accept' --permanent

global_defs {
router_id NGINX_SERVER_1 # Unique identifier for this server
}

vrrp_script chk_nginx {
script "pidof nginx"
interval 2
}

vrrp_instance VI_1 {
interface eth0 # Network interface
state MASTER # Set to MASTER on one server and BACKUP on others
virtual_router_id 51
priority 100 # Set to a higher value on the MASTER server
advert_int 1
authentication {
auth_type PASS
auth_pass password # Authentication password
}
track_script {
chk_nginx
}
virtual_ipaddress {
192.168.1.100 # Virtual IP address
}
}
