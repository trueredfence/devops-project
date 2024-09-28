#!/bin/bash
red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`
echo "${red}Agent CNC Installation start please wait it will take time"
echo "${green}========================================================"
echo "================================================================"
echo "                                                                "
echo "          VERSION 1.0 Centos 7                                  "
echo "                                                                "
echo "================================================================"
echo "${reset}"
echo ""
echo "First Updating server before configure"
echo "${red}Installing apache server 2.++{reset}"
echo "${green}==========================================================${reset}"
yum update -y
yum install vim wget expect firewalld httpd rysnc -y
systemctl start firewalld
systemctl enable firewalld
echo "${red}Restarting service of httpd${reset}"
echo "${green}==========================================================${reset}"
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
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -subj "/C=BN/ST=Bsdf/L=sfffsr/O=Dis Security/OU=IT Department/CN=cnc" -keyout /etc/ssl/private/apache-selfsigned.key -out /etc/ssl/certs/apache-selfsigned.crt
openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
cat /etc/ssl/certs/dhparam.pem | tee -a /etc/ssl/certs/apache-selfsigned.crt
echo "${red}Configure SSL Virtual Hosting with rewrite rules${reset}"
echo "${green}==========================================================${reset}"
rm -Rf /etc/httpd/conf.d/vhost.conf
mkdir -p /var/www/html/cnc
chown -Rf apache.apache /var/www/html/cnc
vhostfile="/etc/httpd/conf.d/vhost.conf"
(cat <<'EOF'
NameVirtualHost *:443
<VirtualHost *:443>
    SSLEngine On
    SSLCertificateFile /etc/ssl/certs/apache-selfsigned.crt
    SSLCertificateKeyFile /etc/ssl/private/apache-selfsigned.key
    ServerAdmin abc@cnc.com
    ServerName cnc
    <Directory /var/www/html/cnc>
        AllowOverride All
        Options -Indexes 
    </Directory>
        DocumentRoot /var/www/html/cnc
        DirectoryIndex index.php
        ErrorLog /var/log/httpd/cnc-error.log
        CustomLog /var/log/httpd/cnc-access.log combined
</VirtualHost>
EOF
) >> $vhostfile
mv /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.back
sed '/^#\|^$\| *#/d' /etc/httpd/conf/httpd.conf.back >> /etc/httpd/conf/httpd.conf
sed -i '/<Directory "\/var\/www\/html">/,/<\/Directory>/s/AllowOverride None/AllowOverride All/' /etc/httpd/conf/httpd.conf
(cat <<EOF
NameVirtualHost *:80
<VirtualHost *:80>
    ServerAdmin abc@cnc
    DocumentRoot /var/www/html/cnc
    ServerName cnc
    ErrorLog logs/cnc-error80
    CustomLog logs/cnc-access80 common
</VirtualHost>
EOF
) >> /etc/httpd/conf/httpd.conf
rpm -Uvh http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
rpm -Uvh http://mirror.webtatic.com/yum/el7/webtatic-release.rpm
yum install php70w.x86_64 php70w-mysqlnd php70w-mcrypt -y
yum install phpmyadmin -y 
cp /etc/httpd/conf.d/phpMyAdmin.conf /etc/httpd/conf.d/phpMyAdmin.conf.back
sed -i '/^Alias/d' /etc/httpd/conf.d/phpMyAdmin.conf
sed -i "s/.*<Directory \/usr\/share\/phpMyAdmin\/>.*/Alias \/hunt \/usr\/share\/phpMyAdmin\n&/" /etc/httpd/conf.d/phpMyAdmin.conf
sed -i 's/.*<RequireAny>.*/&\nRequire all granted/' /etc/httpd/conf.d/phpMyAdmin.conf
sed -i 's/upload_max_filesize = .*/upload_max_filesize = 2048M/' /etc/php.ini
sed -i 's/post_max_size = .*/post_max_size = 2048M/' /etc/php.ini
sed -i 's/max_execution_time = .*/max_execution_time = 300/' /etc/php.ini
sed -i 's/max_file_uploads = .*/max_file_uploads = 100/' /etc/php.ini
systemctl restart httpd.service
rpm -Uvh http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm
sed -i '/[mysql56-community]/,/gpgcheck=1/s/enabled=1/enabled=0/' /etc/yum.repos.d/mysql-community.repo
sed -i '/[mysql57-community]/,/gpgcheck=1/s/enabled=0/enabled=1/' /etc/yum.repos.d/mysql-community.repo
yum install mysql-server -y
systemctl start mysqld
systemctl enable mysqld
MYSQLPWD=$(grep 'temporary password' /var/log/mysqld.log | awk '{print $NF}')
tee ~/secure_our_mysql.sh > /dev/null << EOF
spawn $(which mysql_secure_installation)
expect "Enter password for user root:"
send "$MYSQLPWD\r"
expect "New password:"
send "Admin@4680\r"
expect "Re-enter new password:"
send "Admin@4680\r"
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
rm -v ~/secure_our_mysql.sh
sed -i 's/.*symbolic-links=0.*/&\nsql_mode="NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION"/' /etc/my.cnf
systemctl restart mysqld
cat <<EOF > /opt/mysqldump.sh
#!/bin/bash
backup_path="/var/www/html/cnc/app/mount/backups/dumpsql"
backup_path1="/var/www/html/cnc/app/tmpm/backups/dumpsql"
date=$(date +"%d-%b-%Y")
mysqldump --user=root --password=Admin@4680 --host=localhost CNC | gzip > $backup_path/$date.gz
mysqldump --user=root --password=Admin@4680 --host=localhost CNC | gzip > $backup_path1/$date.gz
find $backup_path/ -type f -mtime +7 -name '*.gz' -execdir rm -- {} \;
find $backup_path1/ -type f -mtime +7 -name '*.gz' -execdir rm -- {} \;
EOF
chmod +x /opt/mysqldump.sh
cat <<EOF > /opt/rysn.sh
#!/bin/bash
if (( $(ps ax | grep rsync | grep mount | wc -l) < 1 )); then /usr/bin/rsync -azh /var/www/html/cnc/app/mount/ /var/www/html/cnc/app/tmpm/; fi;
EOF
chmod +x /opt/rysn.sh
echo "0 * * * * /bin/bash /opt/mysqldump.sh" | tee -a /var/spool/cron/root
echo "* * * * * /bin/bash /opt/rsync.sh" | tee -a /var/spool/cron/root
echo "0 */2 * * * find /var/www/html/cnc/app/mount/tmpinput/ -type d -empty -delete" | tee -a /var/spool/cron/root
echo "0 */2 * * * find /var/www/html/cnc/app/tmpm/tmpinput/ -type d -empty -delete" | tee -a /var/spool/cron/root
echo "0 */2 * * * find /var/www/html/cnc/app/tmpm/lockedfiles/ -type d -empty -delete" | tee -a /var/spool/cron/root
echo "0 */2 * * * find /var/www/html/cnc/app/mount/lockedfiles/ -type d -empty -delete" | tee -a /var/spool/cron/root
