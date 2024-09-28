#!/bin/bash
yum install mod_ssl -y
mkdir /etc/ssl/private
chmod 700 /etc/ssl/private
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -subj "/C=BN/ST=Bsdf/L=sfffsr/O=Dis Security/OU=IT Department/CN=quickmail.com" -keyout /etc/ssl/private/apache-selfsigned.key -out /etc/ssl/certs/apache-selfsigned.crt
openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
cat /etc/ssl/certs/dhparam.pem | tee -a /etc/ssl/certs/apache-selfsigned.crt
echo "${red}Configure SSL Virtual Hosting with rewrite rules${reset}"
echo "${green}==========================================================${reset}"
rm -Rf /etc/httpd/conf.d/vhost.conf
vhostfile="/etc/httpd/conf.d/vhost.conf"
(cat <<'EOF'
NameVirtualHost *:443
<VirtualHost *:443>
    SSLEngine On
    SSLCertificateFile /etc/ssl/certs/apache-selfsigned.crt
    SSLCertificateKeyFile /etc/ssl/private/apache-selfsigned.key
EOF
) >> $vhostfile
read -p "${green}Provide Domain name for host ${red}[e.g abc.xyz.com]${reset}: " VDOMAIN
while [[ -z "$VDOMAIN" ]]
do
   read -p "${green}You Must Select a domain for this ${red}[e.g abc.xyz.com]${reset}: " VDOMAIN
done
echo "${green}Your choice for Virtual Hosting domain is ${red}$VDOMAIN ${reset}"
echo "${green}==========================================================${reset}"
echo ""
(cat <<EOF
	ServerAdmin abc@${VDOMAIN}
    ServerName ${VDOMAIN}
EOF
) >> $vhostfile
read -p "${green}Provide Virtual Directory for /var/www/html/your-directory ${red} [e.g prism] ${reset}: " VIRTAULDIR
while [[ -z "$VIRTAULDIR" ]]
do
   read -p "${green}You Must Select a Virtual Directory for /var/www/html/your-directory  ${red}[e.g prism]${reset}: " VIRTAULDIR
done
mkdir -p /var/www/html/$VIRTAULDIR
chown -Rf apache.apache /var/www/html/$VIRTAULDIR
(cat <<EOF 
	<Directory /var/www/html/${VIRTAULDIR}>
        AllowOverride All
        Options -Indexes
        SeverSignature off
        ServerTokens Prod
        FileETag None
    </Directory>
        DocumentRoot /var/www/html/${VIRTAULDIR}
        DirectoryIndex index.php
        ErrorLog /var/log/httpd/agent-https-error.log
        CustomLog /var/log/httpd/agent-https-access.log combined
    </VirtualHost>
EOF
) >> $vhostfile