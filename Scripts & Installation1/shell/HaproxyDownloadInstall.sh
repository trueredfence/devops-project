#!/bin/bash
#--------------------------------------------
#Copy first Crt file issue by SSL Provider
#Pvt Key gen during CSR 
#ca-bundele issue by SSL Provider
#--------------------------------------------
read -p "Provide Domain name for haproxy [xyz.com]: " VDOMAIN
while [[ -z "$VDOMAIN" ]]
do
   read -p "You Must Select a domain for this [xyz.com]$: " VDOMAIN
done
yum update -y
yum install epel-release vim wget firewalld mod_ssl policycoreutils-python gcc pcre-static pcre-devel openssl-devel -y
wget https://www.haproxy.org/download/2.4/src/haproxy-2.4.0.tar.gz -O ~/haproxy.tar.gz
tar xzvf ~/haproxy.tar.gz
cd ~/haproxy-2.4.0
make TARGET=linux-glibc USE_PCRE=1 USE_OPENSSL=1 USE_ZLIB=1 USE_CRYPT_H=1 USE_LIBCRYPT=1
make install
mkdir -p /etc/haproxy &&  mkdir -p /var/lib/haproxy &&  touch /var/lib/haproxy/stats &&  ln -s /usr/local/sbin/haproxy /usr/sbin/haproxy &&  cp examples/haproxy.init /etc/init.d/haproxy &&  chmod 755 /etc/init.d/haproxy && systemctl daemon-reload && chkconfig haproxy on && useradd -r haproxy
mv ~/cert.txt /etc/ssl/${VDOMAIN}.crt
touch /etc/haproxy/haproxy.cfg
(cat <<EOF
global
        default-path config
        zero-warning
        chroot /var/empty
        user haproxy
        group haproxy
        daemon
        pidfile /var/run/haproxy-svc1.pid
        hard-stop-after 5m
        stats socket /var/run/haproxy-svc1.sock level admin mode 600 user haproxy expose-fd listeners
        stats timeout 1h
        log stderr local0 info
        ssl-default-bind-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384
        ssl-default-bind-options prefer-client-ciphers no-sslv3 no-tlsv10 no-tlsv11 no-tls-tickets
       h1-case-adjust content-length Content-Length
defaults http
        mode http
        option httplog
        log global
        timeout client 1m
        timeout server 1m
        timeout connect 10s
        timeout http-keep-alive 2m
        timeout queue 15s
frontend pub1
        bind :80 name clear
        bind :443 ssl crt /etc/ssl/changeme.crt no-sslv3 alpn h2,http/1.1
        http-after-response set-header Strict-Transport-Security "max-age=31536000"
        http-request redirect scheme https unless { ssl_fc }
        mode http
        acl domain-1 hdr(host) -i changeme
        use_backend backend-1 if domain-1
        option http-ignore-probes
backend backend-1
        option forwardfor # X-Forwarder
        balance roundrobin
        mode http
        server webserver1 146.70.20.242:443 check weight 1 maxconn 50 ssl verify none
        option h1-case-adjust-bogus-server
        #Cache Settings
        cache cache
        total-max-size 200        # RAM cache size in megabytes
        max-object-size 10485760  # max cacheable object size in bytes
        max-age 3600              # max cache duration in seconds
        process-vary on
EOF
) >> /etc/haproxy/haproxy.cfg
sed -i '/pub1/,/option http-ignore-probes/s/changeme/'${VDOMAIN}/ /etc/haproxy/haproxy.cfg
systemctl start firewalld && systemctl enable firewalld
firewall-cmd --permanent --add-service=https --zone=trusted &&
firewall-cmd --permanent --add-service=http --zone=trusted &&
firewall-cmd --permanent --remove-service=http --zone=public &&
firewall-cmd --permanent --remove-service=https --zone=public &&
firewall-cmd --set-default-zone=trusted &&
firewall-cmd --reload
yum remove httpd -y
systemctl start haproxy && systemctl enable haproxy && systemctl status haproxy
echo ""
echo "================================================================"
echo "================================================================"
echo "                                                                "
echo "        Installed Haproxy successfully                          "
echo "                                                                "
echo "================================================================"