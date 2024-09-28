#!/bin/bash
PATH=$PATH:/bin:/usr/bin:/usr/sbin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export PATH
# * * * * * /bin/bash /ununtuNas.sh /dev/null 2>&1
start(){
	
	pid=`ps -ef | grep centosNas.sh | grep -v "grep" | wc -l` # Check if file nasfirewall.sh is running	
	if [ $pid -gt 2 ];
	then
	{					
		exit 1																		
	}
	else
	{	while (( n = 1 ))  															
		do
		{	
			sleep 5;
			if [[ $(ifconfig | grep ppp0 | wc -l) -ge 1 ]]; 
			then  
			{	
				#echo "ppton";
				if [[ $(iptables -L | grep DROP | grep 192.168.12.50 | wc -l) -ge 1 ]];
				then				
				{
					echo "already locked";
				}
				else
				{	
					echo "rule added"
					iptables -A OUTPUT -d 192.168.12.50 -j DROP
					#firewall-cmd --direct --add-rule ipv4 filter OUTPUT 1 -d 192.168.12.50 -j DROP
				}
				fi;
			}
			else
			{
				#echo "no pptp";
				if [[ $(iptables -L | grep DROP | grep 192.168.12.50 | wc -l) -ge 1 ]];
				then
				{
					echo "rule cleaned";
					iptables -F;
					iptables-save;
					#systemctl restart firewalld.service;
				}
				else
				{
					echo "already cleaned";
				}
			 	fi;			
			}
			fi;			

		}
		done
	}
	fi
}
start