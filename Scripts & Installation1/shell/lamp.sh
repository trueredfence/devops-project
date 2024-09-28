#!/bin/bash
# php.ini upload
# remove alias in phpmyadmin.conf
red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`
echo "${red}Agent CNC Installation start please wait it will take time"
echo "${green}========================================================"
echo "================================================================"
echo "                                                                "
echo "		    VERSION 1.0 Centos 7                                  "
echo "                                                                "
echo "================================================================"
echo "${reset}"
echo ""
echo "First Updating server before configure"
echo "${red}Installing apache server 2.++{reset}"
echo "${green}==========================================================${reset}"
#yum update -y
yum install vim wget expect firewalld httpd -y
systemctl start firewalld
systemctl enable firewalld
echo "${red}Restarting service of httpd${reset}"
echo "${green}==========================================================${reset}"
#systemctl start httpd.service
#systemctl enable firewalld
echo "${red}Adding port in firewall for http access${reset}"
echo "${green}==========================================================${reset}"
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --reload
echo "${red}Install and enable SSl Mode of Apache${reset}"
echo "${green}==========================================================${reset}"
yum install mod_ssl -y
mkdir /etc/ssl/private
chmod 700 /etc/ssl/private
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -subj "/C=BN/ST=Bsdf/L=sfffsr/O=Dis Security/OU=IT Department/CN=printerupdates.online" -keyout /etc/ssl/private/apache-selfsigned.key -out /etc/ssl/certs/apache-selfsigned.crt
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
        #SeverSignature off
        #ServerTokens Prod
    </Directory>
        DocumentRoot /var/www/html/${VIRTAULDIR}
        DirectoryIndex index.php
        ErrorLog /var/log/httpd/agent-https-error.log
        CustomLog /var/log/httpd/agent-https-access.log combined
    </VirtualHost>
EOF
) >> $vhostfile
echo "${green}==========================================================${reset}"
echo ""
echo "${green}Please not that your log file for access and error on SSL site are ${red}cnc-error.log and cnc-access.log${reset}"
echo "${green}==========================================================${reset}"
echo ""
echo "${red}Creating htaccess file in /var/www/html/$VIRTAULDIR${reset}"
echo "${green}==========================================================${reset}"
echo ""
read -p "${green}Default file name of php in /var/www/html/$VIRTAULDIR ${red} [e.g abcd.php] ${reset}: " DEFAULTPHPFILENAME
(cat <<EOF
ServerSignature Off
Options -MultiViews
Options -Indexes
IndexIgnore *
RewriteEngine On
RewriteCond %{REQUEST_FILENAME} !-d
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-l
RewriteRule ^(.+)$ ${DEFAULTPHPFILENAME}?url=\$1 [QSA,L]
<Files *.txt>
order allow,deny 
deny from all 
</Files>
EOF
) >> /var/www/html/$VIRTAULDIR/.htaccess   
echo "" >> /var/www/html/$VIRTAULDIR/index.php
echo "${red}Backup Httpd conf file${reset}"
echo "${green}==========================================================${reset}"
mv /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.back
sed '/^#\|^$\| *#/d' /etc/httpd/conf/httpd.conf.back >> /etc/httpd/conf/httpd.conf
echo "${red}Editing httpd.conf file to RewriteRules${reset}"
echo "${green}==========================================================${reset}"
sed -i '/<Directory "\/var\/www\/html">/,/<\/Directory>/s/AllowOverride None/AllowOverride All/' /etc/httpd/conf/httpd.conf
(cat <<EOF
NameVirtualHost *:80
<VirtualHost *:80>
    ServerAdmin webmaster@dummy-host.example.com
    DocumentRoot /var/www/html/${VIRTAULDIR}
    ServerName ${VDOMAIN}
    ErrorLog logs/agent-http-error_log
    CustomLog logs/agent-http-access_log common
</VirtualHost>
EOF
) >> /etc/httpd/conf/httpd.conf
echo "${red}PHP 7.0 Installation Starts${reset}"
echo "${green}==========================================================${reset}"
rpm -Uvh http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
rpm -Uvh http://mirror.webtatic.com/yum/el7/webtatic-release.rpm
#yum clean metadata
#yum clean all
yum install php70w.x86_64 php70w-mysqlnd php70w-mcrypt -y
echo ""
echo "${red}Installing phpmyadmin${reset}"
echo "${green}==========================================================${reset}"
yum install phpmyadmin -y 
cp /etc/httpd/conf.d/phpMyAdmin.conf /etc/httpd/conf.d/phpMyAdmin.conf.back
sed -i '/^Alias/d' /etc/httpd/conf.d/phpMyAdmin.conf
read -p "${green}PHPMyadin Alias Name ${red} [e.g hunterrrr] ${reset}: " PHPMYADMINALIAS
if [[ -n "$PHPMYADMINALIAS" ]]; then
sed -i "s/.*<Directory \/usr\/share\/phpMyAdmin\/>.*/Alias \/$PHPMYADMINALIAS \/usr\/share\/phpMyAdmin\n&/" /etc/httpd/conf.d/phpMyAdmin.conf
fi
sed -i 's/.*<RequireAny>.*/&\nRequire all granted/' /etc/httpd/conf.d/phpMyAdmin.conf
sed -i 's/upload_max_filesize = .*/upload_max_filesize = 2048M/' /etc/php.ini
sed -i 's/post_max_size = .*/post_max_size = 2048M/' /etc/php.ini
sed -i 's/max_execution_time = .*/max_execution_time = 300/' /etc/php.ini
sed -i 's/max_file_uploads = .*/max_file_uploads = 100/' /etc/php.ini
systemctl restart httpd.service
echo ""
echo "${red}Installing MYSQL${reset}"
echo "${green}==========================================================${reset}"
rpm -Uvh http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm
sed -i '/[mysql56-community]/,/gpgcheck=1/s/enabled=1/enabled=0/' /etc/yum.repos.d/mysql-community.repo
sed -i '/[mysql57-community]/,/gpgcheck=1/s/enabled=0/enabled=1/' /etc/yum.repos.d/mysql-community.repo
yum install mysql-server -y
systemctl start mysqld
systemctl enable mysqld
MYSQLPWD=$(grep 'temporary password' /var/log/mysqld.log | awk '{print $NF}')
read -p "${green}Provide root password for Mysql you want to set ${reset}: " NEWMYSQLPWD
#install mysql automactically with new password
tee ~/secure_our_mysql.sh > /dev/null << EOF
spawn $(which mysql_secure_installation)
expect "Enter password for user root:"
send "$MYSQLPWD\r"
expect "New password:"
send "$NEWMYSQLPWD\r"
expect "Re-enter new password:"
send "$NEWMYSQLPWD\r"
expect "Change the password for root ?"
send "n\r"
expect "Remove anonymous users? (Press y|Y for Yes, any other key for No) :"
send "y\r"
expect "Disallow root login remotely? (Press y|Y for Yes, any other key for No) :"
send "y\r"
expect "Remove test database and access to it? (Press y|Y for Yes, any other key for No) :"
send "y\r"
expect "Reload privilege tables now? (Press y|Y for Yes, any other key for No) :"
send "y\r"
EOF
expect ~/secure_our_mysql.sh
# Cleanup
rm -v ~/secure_our_mysql.sh
sed -i 's/.*symbolic-links=0.*/&\nsql_mode="NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION"/' /etc/my.cnf
systemctl restart mysqld
