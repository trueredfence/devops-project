#!/bin/bash
PATH=$PATH:/bin:/usr/bin:/usr/sbin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export PATH
G_HOST=8.8.8.8

start(){

	pid=`ps -ef | grep nasfirewall.sh | grep -v "grep" | wc -l` # Check if file nasfirewall.sh is running
	#checkRule=`iptables -L | grep 192.168.12.50 | grep -v "grep" | wc -l` # Check if firewall alreay have rule
	if [ $pid -gt 3 ];																#	checks if process is already running
	then
	{					
		exit 1																		#	if process is running
	}
	else
	{	while (( n = 1 ))  															#	Infinite loop
		do
		{
			P1ng $G_HOST 
			P_Res_GHOST=$?
			if [[ 100 -eq "$P_Res_GHOST" ]];
			then
			{
				systemctl restart firewalld.service;
			}	
			else
			{								
				firewall-cmd --direct --add-rule ipv4 filter OUTPUT 1 -d 192.168.12.50 -j DROP
				#firewall-cmd --direct --add-rule ipv4 filter OUTPUT 1 -d 192.168.12.51 -j DROP				
			} 
			fi			
		}
		done
	}
	fi
}

P1ng()																				#	Checks Connectivity To Given HOST IP
{
	PINGRES="$(ping -c 2 $1 -D)" 
	PLOSS=`echo $PINGRES : | grep -oP '\d+(?=% packet loss)'`
	#echo "$PINGRES" | tee -a "$Log_Loc/$1.log"
	#echo "----------------------------------------------------------------------------" 
	#echo "$DATE : Loss Result : $1 : $PLOSS"
	#echo "----------------------------------------------------------------------------" 
	return $PLOSS
}

start