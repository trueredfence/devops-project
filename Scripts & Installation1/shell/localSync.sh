#!/bin/bash
# Run Script in Cron tab in every 5 minute will fetchdata from machine
PATH=$PATH:/bin:/usr/bin:/usr/sbin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export PATH
FILE_NAME=localSync.sh
REMOTE_URL=netmachine@192.168.10.135:
REMOTE_PATH=/run/media/netmachine/Safe/X-Ray/
LOCAL_PATH=/run/media/development/Safe/X-Ray/
main()
{

	pid11=`ps -ef | grep $FILE_NAME| grep -v "grep" | wc -l`
	# This need to be check
	if [[ $pid11 -ge 2 ]]; 
	then																			#	Syncing Process Start
		{
			#echo "not found";
			if [[ $(df -h | grep "Safe" | wc -l) -ge 1 ]];then                        
            	rsync -avzhP -e 'ssh' $REMOTE_URL$REMOTE_PATH $LOCAL_PATH 
	    	fi
		}
	else																			#	Process Is In Progress
		{
			
			exit 0
		}
	fi	
}

main