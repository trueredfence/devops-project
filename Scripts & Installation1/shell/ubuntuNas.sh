#!/bin/bash

PATH=$PATH:/bin:/usr/bin:/usr/sbin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export PATH
# * * * * * /bin/bash /ununtuNas.sh /dev/null 2>&1
start(){
	sleep 3
	pid=`ps -ef | grep ubuntuNas.sh | grep -v "grep" | wc -l` # Check if file nasfirewall.sh is running	
	if [ $pid -gt 3 ];
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
				if [[ $(ufw status | grep 192.168.12.50 | wc -l) -ge 1 ]];
				then
				{
					echo "already ruled added"
				}	
				else
				{	
					/usr/sbin/ufw deny out to 192.168.12.50;
					echo "rule added";
				}
				fi;
			}
			else
			{
				sleep 5;
				if [[ $(ufw status | grep 192.168.12.50 | wc -l) -ge 1 ]];
				then
				{
					/usr/sbin/ufw delete deny out to 192.168.12.50;
					echo "rule removed";
				}	
				else
				{	
			 		echo "No need to delete"
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
