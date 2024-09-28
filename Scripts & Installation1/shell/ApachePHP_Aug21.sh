#!/bin/bash
# echo "<?php phpinfo(); ?>" | sudo tee /var/www/html/info.php

echo ""
echo "================================================================"
echo "================================================================"
echo "                                                                "
echo "		    APACHE & PHP 7 CONFIGURE IN CENTOS7               "
echo "                                                                "
echo "================================================================"
#rpm -ivh http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm
rpm -Uvh http://mirror.webtatic.com/yum/el7/webtatic-release.rpm
# For php 8
sudo yum install https://rpms.remirepo.net/enterprise/remi-release-7.rpm -y

yum update -y
yum install epel-release -y
yum install vim wget expect firewalld httpd mod_ssl php70w.x86_64 php70w-mcrypt policycoreutils-python -y
# yum --enablerepo=epel remove mod_security mod_evasive -y
systemctl start httpd && systemctl enable httpd && systemctl status httpd
systemctl start firewalld && systemctl enable firewalld
sudo sed -i 's/SELINUX=disabled.*/SELINUX=enabled/' /etc/selinux/config  
read -p "Provide Domain name for host [xyz.com]: " VDOMAIN
while [[ -z "$VDOMAIN" ]]
do
   read -p "You Must Select a domain for this [xyz.com]$: " VDOMAIN
done
#read -p "IP Address of Haproxy allowed: " HAPROXYIP
#while [[ -z "$HAPROXYIP" ]]
#do
   #read -p "IP Address of Haproxy allowed: " HAPROXYIP
#done

randomfile=`cat /dev/urandom | env LC_CTYPE=C tr -cd 'A-Za-f0-9' | head -c 32`
randomphp=`cat /dev/urandom | env LC_CTYPE=C tr -cd 'A-Za-f0-9' | head -c 12`
vhostfile="/etc/httpd/conf.d/${VDOMAIN}.conf"
#chmod –R 750 bin conf
mkdir /etc/ssl/private
chmod 700 /etc/ssl/private
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -subj "/C=BN/ST=Bsdf/L=sfffsr/O=Dis Security/OU=IT Department/CN=${VDOMAIN}" -keyout /etc/ssl/private/${VDOMAIN}.key -out /etc/ssl/private/${VDOMAIN}.crt
mkdir -p /var/www/html/$randomfile
touch /var/www/html/$randomfile/$randomphp.php
mkdir -p /home/data
chown -Rf apache.apache /var/www/html/$randomfile

(cat <<EOF
#NameVirtualHost *:443
#ServerTokens Prod
#ServerSignature Off
ServerTokens Full
SecServerSignature "$randomphp"
FileETag None
TraceEnable off
HostnameLookups Off
Header always set X-Content-Type-Options nosniff
Header always set X-XSS-Protection "1; mode=block"
Header always append X-Frame-Options SAMEORIGIN
<VirtualHost *:443>
    SSLEngine On
    SSLProtocol all -SSLv2 -SSLv3
    SSLHonorCipherOrder on
    SSLCipherSuite "EECDH+ECDSA+AESGCM EECDH+aRSA+AESGCM EECDH+ECDSA+SHA384 EECDH+ECDSA+SHA256 EECDH+aRSA+SHA384 EECDH+aRSA+SHA256 EECDH+aRSA+RC4 EECDH EDH+aRSA RC4 !aNULL !eNULL !LOW !3DES !MD5 !EXP !PSK !SRP !DSS !RC4"
    SSLCertificateFile /etc/ssl/private/$VDOMAIN.crt
    SSLCertificateKeyFile /etc/ssl/private/$VDOMAIN.key
    ServerAdmin abc@$VDOMAIN
    ServerName $VDOMAIN
    SetEnv DB_NAME agent
    SetEnv DB_PASS HGet$^%2(826lkSrwNbdFg2#%
    SetEnv DB_USER root
    setEnv BASE_DIR $randomfile
    DocumentRoot /var/www/html/$randomfile
    <Directory /var/www/html/$randomfile>
        Options -Indexes -Includes -ExecCGI -FollowSymLinks +SymLinksIfOwnerMatch
        AllowOverride All
    </Directory>
    DirectoryIndex index.html index.php
    ErrorLog /var/log/httpd/private_error.log
    CustomLog /var/log/httpd/private_access.log combined
</VirtualHost>
EOF
) >> $vhostfile

echo "Creating htaccess file with default Configuration"
echo "================================================="
echo ""

(cat <<EOF
ServerSignature Off
Options -Indexes
#Hide Extension of File
Options -MultiViews
RewriteEngine On
RewriteCond %{REQUEST_FILENAME} !-d
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-l
RewriteRule ^(.+)$ $randomphp.php?url=\$1 [QSA,L]
<Files *.txt>
order allow,deny 
deny from all 
</Files>
EOF
) >> /var/www/html/$randomfile/.htaccess   

echo "Changing Httpd.conf file"
echo "================================================="
echo ""
mv /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.back
sed '/^#\|^$\| *#/d' /etc/httpd/conf/httpd.conf.back >> /etc/httpd/conf/httpd.conf
#if apache is behind proxy
sed -e '/IfModule log_config_module>/{n;d}' /etc/httpd/conf/httpd.conf
# else not required
sed -i 's/.*<IfModule log_config_module>.*/&\n\tLogFormat "%h %{X-Forwarded-For}i %l %u %t \\"%r\\" %>s %O \\"%{Referer}i\\" \\"%{User-Agent}i\\"" combined/' /etc/httpd/conf/httpd.conf
sed -i 's/.*<Directory \/>.*/&\nOptions -Indexes -Includes -ExecCGI -FollowSymLinks/' /etc/httpd/conf/httpd.conf
sed -i 's/.*<Directory "\/var\/www">.*/&\nOptions -Indexes -Includes -ExecCGI -FollowSymLinks/' /etc/httpd/conf/httpd.conf
sed -i '/<Directory "\/var\/www\/html">/,/<\/Directory>/s/Options Indexes FollowSymLinks/Options -Indexes -Includes -ExecCGI -FollowSymLinks/' /etc/httpd/conf/httpd.conf
sed -i '/^IncludeOptional conf.d\/\*\.conf.*/i ServerName 127.0.0.1:80\nServerTokens Prod\nServerSignature Off\nFileETag None\nTraceEnable off\nHostnameLookups Off\nHeader always set X-Content-Type-Options nosniff\nHeader always set X-XSS-Protection "1; mode=block"\nHeader always append X-Frame-Options SAMEORIGIN\nAddOutputFilterByType DEFLATE text/html text/plain text/xml text/css text/javascript application/javascript' /etc/httpd/conf/httpd.conf
touch /var/www/html/index.html && touch /var/www/html/$randomfile/index.html && touch /var/www/html/$randomfile/logevent.txt
chown -Rf apache.apache /var/www/html/index.html && chown -Rf apache.apache /var/www/html/$randomfile/index.html && chown -Rf apache.apache /var/www/html/$randomfile/logevent.txt
echo "Configure SeLinux for Apache"
echo "================================================="
echo ""

#semanage fcontext -l
#(any path for rw permission in seLinux)
#semanage fcontext -a -t httpd_log_t "/var/www/html/$randomfile(/.*)?"
#(For Read and Write)
semanage fcontext -a -t httpd_sys_rw_content_t "/var/www/html/$randomfile(/.*)?"
#HTTPS ACCESS ONLY
semanage fcontext -a -t httpd_sys_content_t "/var/www/html/$randomfile(/.*)?"
restorecon -R -v "/var/www/html/$randomfile"
#For Home Directory
#home Directory Access
#setsebool -P httpd_enable_homedirs true
#semanage fcontext -a -t httpd_sys_content_t "/home/data(/.*)?"
semanage fcontext -a -t httpd_sys_rw_content_t "/home/data(/.*)?"
restorecon -R -v "/home/"

echo "Installing PHP 7"
echo "================================================="
echo ""


echo "Configure PHP.INI"
echo "================================================="
echo ""
sed -i 's/upload_max_filesize = .*/upload_max_filesize = 2048M/' /etc/php.ini
sed -i 's/post_max_size = .*/post_max_size = 2048M/' /etc/php.ini
sed -i 's/max_execution_time = .*/max_execution_time = 300/' /etc/php.ini
sed -i 's/max_file_uploads = .*/max_file_uploads = 100/' /etc/php.ini
sed -i 's/short_open_tag = .*/short_open_tag = On/' /etc/php.ini
sed -i 's/expose_php = .*/expose_php = Off/' /etc/php.ini
sed -i 's/memory_limit = .*/memory_limit = 1024M/' /etc/php.ini
sed -i 's/display_errors = .*/display_errors = Off/' /etc/php.ini

echo "Configure Mod Security"
echo "=============================="
echo ""
sed -i 's/SecRequestBodyLimit .*/SecRequestBodyLimit 2147483647/' /etc/httpd/conf.d/mod_security.conf
sed -i 's/SecRequestBodyNoFilesLimit .*/SecRequestBodyNoFilesLimit 21474/' /etc/httpd/conf.d/mod_security.conf
sed -i 's/SecRequestBodyInMemoryLimit .*/SecRequestBodyInMemoryLimit 21474836/' /etc/httpd/conf.d/mod_security.conf
#filename validation
sed -i 's/SecRule MULTIPART_STRICT_ERROR "!@eq 0" .*/#SecRule MULTIPART_STRICT_ERROR "!@eq 0" \\ /' /etc/httpd/conf.d/mod_security.conf
#Recheck this flag
sed -i 's/SecRule MULTIPART_UNMATCHED_BOUNDARY "!@eq 0" .*/#SecRule MULTIPART_UNMATCHED_BOUNDARY "!@eq 0" \\ /' /etc/httpd/conf.d/mod_security.conf


echo "Cleand Unwanted Files"
echo "================================================="
echo ""
rm -Rf /usr/share/httpd
rm -Rf /etc/httpd/conf.d/welcome.conf
echo "Creating Trusted Zone if firewall"
echo ""
echo ""
#firewall-cmd --permanent --add-source=${PROXYIP} --zone=trusted &
firewall-cmd --permanent --add-service=https --zone=trusted &&
firewall-cmd --permanent --remove-service=http --zone=public &&
firewall-cmd --permanent --remove-service=https --zone=public &&
firewall-cmd --set-default-zone=public &&
firewall-cmd --reload
systemctl reload httpd && systemctl status httpd -l
echo ""
echo ""
echo "Please Reboot your system"
echo "Add trusted zone in firewall if required irewall-cmd --permanent --add-source=1.2.3.4 --zone=trusted"
echo ""
