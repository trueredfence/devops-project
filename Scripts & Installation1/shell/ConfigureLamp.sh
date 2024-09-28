#!/bin/bash
PATH=$PATH:/bin:/usr/bin:/usr/sbin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export PATH

InstallLamp() {

  echo "Choose an option:"
  echo "1. Apache"
  echo "2. Php"
  echo "3. Mysql with PHPMyadmin"
  echo "4. LAMP"
  echo "5. Quit"

  read -p "Enter your choice (1-5): " choice

  case $choice in
  1)
    echo "You chose Option 1"
    # Add your actions for Option 1 here
    InstallApache
    ;;
  2)
    echo "You chose Option 2"
    # Add your actions for Option 2 here
    ;;
  3)
    echo "You chose Option 3"
    # Add your actions for Option 3 here
    ;;
  4)
    echo "You chose Option 4"
    # Add your actions for Option 3 here
    ;;
  5)
    echo "Exiting the script. Goodbye!"
    exit 0
    ;;
  *)
    echo "Invalid choice. Please enter a number between 1 and 4."
    ;;
  esac

}
InstallApache() {
  clear
  read -p "Provide Domain/ip for webhosting: " domain
  read -p "Provide ip address of webserver: " ipaddress
  read -p "Provide port for webserver: " webport

}
InstallLamp
