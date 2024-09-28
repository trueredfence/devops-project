#!/bin/bash
# bash -c "$(curl -H 'Cache-Control: no-cache, no-store' https://raw.githubusercontent.com/devtechfusion/shiny/main/cat.sh)"

# Define colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Add commonly used paths to PATH variable
PATH=$PATH:/bin:/usr/bin:/usr/sbin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export PATH

# Function to display installation banner
displayBanner() {
  echo -e "${GREEN}############################################################${NC}"
  echo -e "${GREEN}#             Nginx Reverse Proxy Installation              #${NC}"
  echo -e "${GREEN}############################################################${NC}"
  echo -e "${YELLOW}This script will install and configure Nginx reverse proxy.${NC}"
  echo -e "${YELLOW}Please follow the prompts to proceed.${NC}"
  echo ""
}

# Function to check system configuration
checkSysConfig() {
  OS_DETAILS=$(cat /etc/os-release | head -2 | tr -d '\n')
  CPU_CORES=$(grep processor /proc/cpuinfo | wc -l)
  SYSTEM_RAM=$(free -h | awk '/^Mem:/{print $2}')

  # Display system information
  echo -e "${GREEN}-------------------------------------------------------------------${NC}"
  echo -e "${GREEN}                    System Information:                           ${NC}"
  echo -e "${GREEN}-------------------------------------------------------------------${NC}"
  echo "Operating System: $OS_DETAILS"
  echo "CPU Cores Available: $CPU_CORES"
  echo "System RAM Available: $SYSTEM_RAM"
  echo -e "${GREEN}-------------------------------------------------------------------${NC}"
}

# Function to check internet connectivity
ifOnline() {
  ping -c 1 $UPSTREAM >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo ""
  else
    echo -e "${YELLOW}Error: Computer with IP/Domain address $UPSTREAM is not available on the network.${NC}"
    StartInstallation
  fi
}

# Function to select network interface for Keepalived
selectInterface() {
  # Get interface names from ifconfig command
  INTERFACES=$(ifconfig -s | awk '{print $1}')

  # Prompt user to select an interface
  echo "Select an interface for Keepalived:"
  select INTERFACE in $INTERFACES; do
    # Check if a valid option was selected
    if [ -n "$INTERFACE" ]; then
      echo "Selected interface: $INTERFACE"
      break
    else
      selectInterface
    fi
  done
}

# Function to prompt user for Keepalived installation
wantToInstallKeepalived() {
  # Prompt user to continue with the installation
  read -p "Do you want to install Keepalived? (yes/no): " answer
  case "$answer" in
  yes)
    echo -e "${YELLOW}Installing Keepalived...${NC}"
    sleep 1
    installKeepAlived
    ;;
  no)
    echo -e "${YELLOW}Exiting the program.${NC}"
    ;;
  *)
    echo -e "${YELLOW}Invalid input. Please enter 'yes' or 'no'.${NC}"
    wantToInstallKeepalived
    ;;
  esac
}

# Function to prompt user to continue with the installation
isContinue() {
  # Prompt user to continue with the installation
  read -p "Do you want to continue with this configuration? (yes/no): " answer
  case "$answer" in
  yes)
    echo -e "${YELLOW}Installation process starting...${NC}"
    sleep 1
    installNginx
    ;;
  no)
    echo -e "${YELLOW}Exiting the program.${NC}"
    exit 1
    ;;
  *)
    echo -e "${YELLOW}Invalid input. Please enter 'yes' or 'no'.${NC}"
    isContinue
    ;;
  esac
}

# Function to install Keepalived
installKeepAlived() {
  # Prompt user for Keepalived configuration
  read -p "Enter virtualIP address for Keepalived: " VIRTUALIP
  while [[ -z "$VIRTUALIP" ]]; do
    read -p "Enter virtualIP address for Keepalived: " VIRTUALIP
  done

  selectInterface

  # Install Keepalived
  dnf install keepalived -y

  # Configure firewall for Keepalived
  echo -e "${YELLOW}Adding firewall rules for Keepalived${NC}"
  firewall-cmd --add-rich-rule='rule protocol value="vrrp" accept' --permanent
  firewall-cmd --reload
  echo -e "${YELLOW}Firewall reloaded${NC}"

  # Start and enable Keepalived service
  systemctl start keepalived
  systemctl enable keepalived

  # Configure Keepalived
  mv /etc/keepalived/keepalived.conf /etc/keepalived/keepalived.conf.back
  touch /etc/keepalived/keepalived.conf

  (
    cat <<EOF
global_defs {
  router_id NGINX_SERVER_1  # Unique identifier for this server
}

vrrp_script chk_nginx {
  script "pidof nginx"
  interval 2
}

vrrp_instance VI_1 {
  interface $INTERFACE  # Network interface
  state MASTER    # Set to MASTER on one server and BACKUP on others
  virtual_router_id 51
  priority 100     # Set to a higher value on the MASTER server
  advert_int 1
  authentication {
    auth_type AH
    auth_pass secret
  }
  track_script {
    chk_nginx
  }
  virtual_ipaddress {
    $VIRTUALIP   # Virtual IP address
  }
}

EOF
  ) >>/etc/keepalived/keepalived.conf
}

# Function to install Nginx
installNginx() {
  # Prompt user for upstream server IP address
  read -p "Enter Backend server IP Address [1.1.1.1:port]: " UPSTREAM
  while [[ -z "$UPSTREAM" ]]; do
    read -p "Enter Backend server IP Address [1.1.1.1:port]: " UPSTREAM
  done

  # Prompt user for Nginx machine IP address or domain name
  read -p "Enter Nginx machine IP address or domain name: " DOMAIN
  while [[ -z "$DOMAIN" ]]; do
    read -p "Enter Nginx machine IP address or domain name: " DOMAIN
  done

  echo -e "${YELLOW}Starting Nginx installation...${NC}"
  sleep 3

  # Install required packages
  sudo dnf install nginx vim firewalld -y

  # Enable and start Nginx
  echo -e "${YELLOW}Enabling & starting Nginx...${NC}"
  sleep 3
  sudo systemctl enable nginx && systemctl start nginx

  # Configure Firewall
  echo -e "${YELLOW}Configuring firewall...${NC}"
  systemctl start firewalld && systemctl enable firewalld
  firewall-cmd --permanent --add-service=https --zone=public &&
    firewall-cmd

  --permanent --add-service=http --zone=public &&
    firewall-cmd --reload
  sleep 2

  # Configure cache directory for Nginx
  echo -e "${YELLOW}Creating cache directory for Nginx...${NC}"
  mkdir -p /var/cache/nginx
  chown -R nginx:nginx /var/cache/nginx

  # Backup existing Nginx configuration file
  echo -e "${YELLOW}Creating backup of /etc/nginx/nginx.conf file...${NC}"
  mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup
  sleep 2

  # Configure SELinux Policy
  echo -e "${YELLOW}Configuring SeLinux Policy...${NC}"
  setsebool -P httpd_can_network_connect 1
  sleep 2

  # Creating Nginx configuration file for load balancer
  echo -e "${YELLOW}Creating Nginx configuration file for load balancer...${NC}"
  touch /etc/nginx/nginx.conf

  (
    cat <<EOF
# Nginx Configuration for Load Balancer
worker_processes $CPU_CORES;
worker_rlimit_nofile 100000;
error_log /var/log/nginx/error.log crit;

events {    
  worker_connections 4000;
  use epoll;
  multi_accept on;
}

http {
  # Define the cache zone
  proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=my_cache:10m max_size=10g inactive=60m;

  upstream backend {
    least_conn;
    server $UPSTREAM;
  }

  server {
    listen 80;    
    server_name $DOMAIN;

    # Enable gzip compression
    gzip on;
    gzip_min_length 10240;
    gzip_comp_level 1;
    gzip_vary on;
    gzip_disable msie6;
    gzip_types text/css text/javascript text/xml text/plain text/x-component application/javascript application/x-javascript application/json application/xml application/rss+xml application/atom+xml font/truetype font/opentype application/vnd.ms-fontobject image/svg+xml;

    # Configure timeouts
    reset_timedout_connection on;
    client_body_timeout 10;
    send_timeout 2;
    keepalive_timeout 30;
    keepalive_requests 100000;

    location / {
      # Forward requests to backend servers
      proxy_pass http://backend;

      # Enable caching
      proxy_cache my_cache;
      proxy_cache_valid 200 302 10m;
      proxy_cache_valid 404 1m;
      proxy_cache_use_stale error timeout invalid_header updating http_500 http_502 http_503 http_504;
      proxy_cache_lock on;
      proxy_cache_lock_timeout 5s;
      proxy_cache_revalidate on;
      proxy_cache_background_update on;
      proxy_cache_min_uses 1;
      proxy_cache_bypass \$http_cache_control;
      add_header X-Cache-Status \$upstream_cache_status;

      # Configure buffering and error handling
      proxy_buffering on;
      proxy_ignore_client_abort on;
      proxy_intercept_errors on;
      
      # Set headers for backend communication
      proxy_set_header Host \$host;
      proxy_set_header X-Real-IP \$remote_addr;
      proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto \$scheme;
    }
  }    
}
EOF
  ) >>/etc/nginx/nginx.conf

  nginx -t
  sleep 1
  systemctl restart nginx
  systemctl enable nginx
  echo -e "${GREEN}Nginx configured successfully.${NC}"
  sleep 2

  # Prompt user for Keepalived installation
  wantToInstallKeepalived
  echo -e "${YELLOW}Configure your SSL manually if required.${NC}"
  sleep 2
  echo -e "${YELLOW}Access your Nginx server at: http://$DOMAIN${NC}"
}

# Main script execution starts here
displayBanner
checkSysConfig
isContinue
