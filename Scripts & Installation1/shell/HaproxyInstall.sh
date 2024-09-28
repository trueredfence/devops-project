#!/bin/bash
#--------------------------------------------
#Copy first Crt file issue by SSL Provider
#Pvt Key gen during CSR 
#ca-bundele issue by SSL Provider
#--------------------------------------------
echo ""
echo "================================================================"
echo "================================================================"
echo "                                                                "
echo "		    HAPROXY CONFIGURE IN CENTOS7                          "
echo "                                                                "
echo "================================================================"
read -p "Provide Domain name for haproxy [xyz.com]: " VDOMAIN
while [[ -z "$VDOMAIN" ]]
do
   read -p "You Must Select a domain for this [xyz.com]$: " VDOMAIN
done
read -p "VPS IP for Haproxy where to redirect: " VPSIP
while [[ -z "$VPSIP" ]]
do
   read -p "VPS IP for Haproxy where to redirect: " VPSIP
done
rpm -Uvh http://mirror.webtatic.com/yum/el7/webtatic-release.rpm
yum update -y
yum install epel-release vim wget firewalld mod_ssl policycoreutils-python haproxy -y
yum group install 'Development Tools' -y

systemctl start haproxy && systemctl enable haproxy && systemctl status haproxy
systemctl start firewalld && systemctl enable firewalld
firewall-cmd --permanent --add-service=https --zone=trusted &&
firewall-cmd --permanent --add-service=http --zone=trusted &&
firewall-cmd --permanent --remove-service=http --zone=public &&
firewall-cmd --permanent --remove-service=https --zone=public &&
firewall-cmd --set-default-zone=trusted &&
firewall-cmd --reload
#Configure HaProxy File
#Backup Haproxy conf file
mv /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.back
sed '/^#\|^$\| *#/d' /etc/haproxy/haproxy.cfg.back >> /etc/haproxy/haproxy.cfg
sed -i 's/.*\/var\/lib\/haproxy\/stats.*/&\n\ttune.ssl.default-dh-param  2048\n\tssl-default-bind-ciphers TLS13-AES-256-GCM-SHA384:TLS13-AES-128-GCM-SHA256:TLS13-CHACHA20-POLY1305-SHA256:EECDH+AESGCM:EECDH+CHACHA20\n\tssl-default-bind-options no-sslv3 no-tlsv10 no-tlsv11/' /etc/haproxy/haproxy.cfg
sed -i "s/.*server  app4 127.0.0.1:5004 check.*/&\n\nfrontend web-f\n\tbind *:80\n\tbind *:443 ssl crt \/etc\/ssl\/${VDOMAIN}.crt no-sslv3\n\thttp-request redirect scheme https unless { ssl_fc }\n\tmode http\n\tacl domain-1 hdr(host) -i ${VDOMAIN}\n\tuse_backend backend-1 if domain-1\n\nbackend backend-1\n\tbalance roundrobin\n\tmode http\n\tserver webserver1 ${VPSIP}:443 check weight 1 maxconn 50 ssl verify none/" /etc/haproxy/haproxy.cfg
touch /etc/ssl/${VDOMAIN}.crt
systemctl restart haproxy && systemctl status haproxy
