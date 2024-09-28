#!/bin/bash
PATH=$PATH:/bin:/usr/bin:/usr/sbin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export PATH
Log_Loc=/home/misa/Desktop/data/logs
HOST_DB=8.8.8.8
HOST_CNC=192.168.2.3
DATE=`date`

start()																				#	Main Function To Check Connectivity & Starting Sync Process
{
	pid=`ps -ef | grep file.sh | grep -v "grep" | wc -l`
	PID=`ps -ef | grep "file.sh" | grep -v "grep" | awk '{print $2}'`
	if [ $pid -gt 3 ];																#	checks if process is already running
	then
	{																				#	if process is running
		echo -e "[$(date)] : file.sh : Process is already running with PID \n $PID"
		exit 1
	}
	else																			#	if process is not running
	{	while (( n = 1 ))  															#	Infinite loop
		do
		{
			P1ng $HOST_CNC 															# 	Ping CNC
			P_Res_CNC=$?
			if [[ 100 -eq "$P_Res_CNC" ]];
			then
			{
				sudo -u root bash -c "sudo ip route add 192.168.2.0/25 via 192.168.2.199"	#	add route to server
				#retVal=$?
				P1ng $HOST_CNC 
				Err0R $? 0 			
			}
			fi

			P1ng $HOST_DB														# 	Ping Google.com
			P_Res_DB=$?
			if [[ 100 -eq "$P_Res_DB" ]];
			then
			{
				sudo -u misa bash -c "nmcli con down id VPN-2"
				sudo -u misa bash -c "nmcli con up id VPN-2"
				echo "$DATE : Started : $HOST"
				sleep 5
				P1ng $HOST_DB 
				Err0R $? 0
				Sync_Start
			}	
			else
			{
				Sync_Start
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
	echo "----------------------------------------------------------------------------" | tee -a "$Log_Loc/$1.log"
	echo "$DATE : Loss Result : $1 : $PLOSS" | tee -a "$Log_Loc/$1.log"
	echo "----------------------------------------------------------------------------" | tee -a "$Log_Loc/$1.log"
	return $PLOSS
}

Err0R()																				#	Error Generated while connecting to HOST
{
	if [ $1 -ne $2 ]; then
		echo "Error"
	fi
}

Sync_Start()																		#	Syncing Process
{
	tput setaf 2; echo -e "Syncing will start soon..."; tput sgr0												
	pid11=`ps -ef | grep sync.sh | grep -v "grep" | wc -l`
	if [[ $pid11 -eq 0 ]]; 
	then																			#	Syncing Process Start
		{
			sudo -u root bash -c "sudo /etc/ppp/peers/sync.sh >> $Log_Loc/sync.log 2>&1"		
			Err0R $? 0
		}
	else																			#	Process Is In Progress
		{
			tput setaf 1; echo "Syncing is in progress"; tput sgr0
			exit 0
		}
	fi
	echo "Syncing Complete"
}

start