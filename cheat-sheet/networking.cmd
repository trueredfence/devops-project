Networking and Routing Cheate sheet
==================================

ip -4 br a  # Get ip and interface status
ip -4 br a  s dev eth0 # Get ip and interface status of select interface
ip route get 8.8.8.8 #to check which path system will take to go to 8.8.8.8
ip route get 8.8.8.8 fibmatch
ip route get 8.8.8.8 from 10.10.10.1 fibmatch
ip route show all # Get all routing detila
ip route show table 123 # get routing inside a table
ip route show scope host table all # host scope routing details local
ip route show scope link table all # link scope routing details connected network
ip route show scope global table all # global scope routing detail for rest all


Note most specif network wins
ip route add 1.1.1.1 via 192.168.10.1
ip route add 1.1.1.0/24 via 192.168.10.2
ip route add default via 192.168.10.3

# based on matrix if two routes add 
ip roue add 1.1.1.1 via 192.168.10.1 metric 100
ip roue add 1.1.1.1 via 192.168.10.2 metric 200

# Firewall marks
ip rule add fwmark table 124
ip rule add lookup main supress_prefixlength 0

ip rule add from 10.10.20.100/29 table 321
ip rule add from 192.168.157.3 table 321

host -t A ifconfig.me

traceroute -n 8.8.8.8