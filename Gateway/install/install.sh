#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color
export TOP_PID=$$

info () {
  printf "=======================================================================================\n"
  printf "+                                 ${MAGENTA}Gateway Script 1.2${NC}                                  +\n"
  printf "=======================================================================================\n"
  printf "| This script will install gateway configurations and requirements automactically     |\n"
  printf "| in centos9 machines                                                                 |\n"
  printf "|                                                                                     |\n"
  printf "| Before Proceed ensure that:                                                         |\n"
  printf "|   1. Internet Connection on gateway machines                                        |\n"
  printf "|   2. All interface should be configured for manual ip not DHCP                      |\n"
  printf "|   3. src folder should be available next to this script                             |\n"
  printf "|   4. Required python 3.11                                                           |\n"
  printf "|                                                                                     |\n"
  printf "| Note:                                                                               |\n"
  printf "|   1. It will create gateway command that will be accessable on terminal directly    |\n"
  printf "|   2. It will create gateway service that will run during shutdown and at startup    |\n"
  printf "|   3. It will install wiregarud dashboard that can be access on                      |\n"
  printf "|      ${YELLOW}http://<serverip>:5000/${NC}                                                        |\n"
  printf "=======================================================================================\n"
}

info

showmsg() {
    case "$1" in
        "i")
            # Info message (yellow)
            echo -e "${YELLOW}$2${NC}"
            ;;
        "e")
            # Error message (red)
            echo -e "${RED}$2${NC}"
            ;;
        "s")
            # Success message (green)
            echo -e "${GREEN}$2${NC}"
            ;;
        *)
            # Default case (cyan and magenta border)
            echo -e "${CYAN}=============================================${NC}"
            echo -e "${MAGENTA}$1${NC}"
            echo -e "${CYAN}=============================================${NC}"
            ;;
    esac
}
# Check requird files 
check_required_files(){
	showmsg i "Checking required files and folder to install gateway"
	local -a src_file=("gateway.service" "wgdashboard.service" "gw-config.ini" "lan-t1.conf" "wan-t1.conf")
	local wgFolder="WGDashboard"
	for file in "${src_file[@]}"; do
        if [[ ! -f "./src/$file" ]]; then
            showmsg e "Error: $file not available. Exiting."
            showmsg i "All required files and folder are present. Proceeding with installation."
            #exit 1
            kill $TOP_PID
        fi
    done

    if [[ ! -d "./src/$wgFolder" ]]; then
        showmsg e "Error: Folder $wgFolder not available. Exiting."
        showmsg i "All required files and folder are present. Proceeding with installation."
        #exit 1
        kill $TOP_PID
    fi
    enable_packet_fwd	
}


install_required_packages(){
	showmsg i "Installing required packages"
	sudo dnf -y update	 && \
	sudo dnf -y install epel-release  && \
	sudo dnf -y groupinstall "Development Tools"  && \
    sudo dnf -y install net-tools wireguard-tools vim traceroute firewalld wget curl git zsh unzip dhcp-server openssl-devel bzip2-devel libffi-devel python3.11 && \
    sudo dnf -y upgrade
    sleep 2 
}

enable_packet_fwd(){
    if ! grep -q "^net.ipv4.ip_forward=" /etc/sysctl.conf; then
        echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf > /dev/null
        sysctl -p
    fi
}

move_file_to_respective_loc(){
	showmsg i "Setting up files to their respective locations"
	local gw_loc="/root/gateway"
	local gw_cmd_loc="/usr/local/bin"
	local service_loc="/etc/systemd/system/"	
	local wg_config="/etc/wireguard"

	# Create folder for gateway config
	mkdir -p "/root/gateway"
	if [[ -f "$gw_loc/gw-config.ini" ]]; then
		showmsg s "Gateway config file already available skipping..."
	fi
	cp "./src/gw-config.ini" "$gw_loc" && \
	cp "./src/gateway.sh" "$gw_cmd_loc/gateway" && \
	chmod +x "$gw_cmd_loc/gateway" && \
	cp "./src/gateway.service" "$service_loc"  && \
	cp "./src/wgdashboard.service" "$service_loc"

	# Move wiregaurd sampel file
	cp "./src/lan-t1.conf" "$wg_config" && \
	cp "./src/wan-t1.conf" "$wg_config"
	showmsg i "File move to successfully"
	sleep 2	
}

install_wg_dashboard(){
	local wg_dashboard="/usr/share"
	cp -rf "./src/WGDashboard" "$wg_dashboard" && \
	cd "$wg_dashboard/WGDashboard/src" && \
	chmod +x ./wgd.sh && \
    ./wgd.sh install && \
    systemctl start firewalld && \
 	firewall-cmd --add-port=5000/tcp --permanent && \
    firewall-cmd --reload && \
    ./wgd.sh start && \
    ./wgd.sh stop     
}

configure_wg_dashboard(){
	local wgconfig="/usr/share/WGDashboard/src/wg-dashboard.ini"
	if [[ -f "$wgconfig" ]]; then
	    sed -i 's/app_port[[:space:]]*=[[:space:]]*[0-9]*/app_port = 5000/' $wgconfig   
	    read -p "Enter LAN IP of gateway to access WG Dashboard: " user_ip
	    sed -i "s/app_ip[[:space:]]*=[[:space:]]*[0-9.]*/app_ip = $user_ip/" "$wgconfig"
	    sudo systemctl daemon-reload 
	    sudo systemctl enable --now wgdashboard.service 
	else
		showmsg i "unable install wgdashboard please install manually or handle error first"
	fi
}

reload_system_service(){
	showmsg i "Reloading the services"
	sudo systemctl daemon-reload
    sudo systemctl enable --now gateway.service 
}

install_zshell(){
	showmsg i "Installing zshell"
	if [[ "$SHELL" == *"zsh"* ]]; then
        showmsg s "Current shell is zsh. Skipping shell installation."
    else
	bash -c "$(curl -H 'Cache-Control: no-cache, no-store' https://raw.githubusercontent.com/trueredfence/kali-linux-terminal/refs/heads/main/install.sh)"
	fi
}


init(){
	 showmsg "Initializing the gateway installation..."
	 check_required_files
	 install_required_packages
	 move_file_to_respective_loc
     sleep 1
	 install_wg_dashboard
     sleep 1
	 configure_wg_dashboard
	 sleep 1
     reload_system_service
	 sleep 1
     install_zshell
     rm -rf "./src"
	 showmsg "Your system is configure to use gateway script please reboot once before proceed."
}

# Prompt the user for input
read -p "Do you want to install the gateway? (y/Y/yes): " user_input

# Check the input
if [[ "$user_input" == "y" || "$user_input" == "Y" || "$user_input" == "yes" ]]; then
    init
else
    echo "Exiting the script."
    #exit 1
    kill $TOP_PID
fi