#!/usr/bin/python3
import os
import sys
from datetime import datetime
import shutil

data_folder_name="Data_as_on_Test"+str(datetime.today().strftime('%d %b %Y'))
key_log_folder_name="Keylog_as_on_"+str(datetime.today().strftime('%d %b %Y'))
detPath='dtes/'
currentData= 'Data/'
current_year=str(datetime.today().strftime('%Y'))
current_month=str(datetime.today().strftime('%h %y'))
mountPoint=os.path.join(os.path.expanduser('~'), 'Desktop', 'Data')
nas_username="analysis"
nas_pass="Bmt28R$e*3" # Chagne this password

#nas_path="/home/netmachine/Desktop/Data"
# Create Mount point if not exist
if not os.path.exists(mountPoint):os.makedirs(mountPoint)
if not os.path.ismount(mountPoint):
	print("Mounting //192.168.12.57/analysis/DATA/X_RAY_DATA/ to "+mountPoint)
	os.system("sudo mount -t cifs -o file_mode=0777,dir_mode=0777,vers=3.0,username=analysis,password='"+nas_pass+"' //192.168.12.57/analysis/DATA/X_RAY_DATA/ /home/netmachine/Desktop/Data") 
if not os.path.exists(os.path.join(mountPoint,current_year,current_month)):os.makedirs(os.path.join(mountPoint,current_year,current_month))
todayDataFolder = os.path.join(mountPoint,current_year,current_month,data_folder_name)	
if os.path.exists(todayDataFolder):
	print(todayDataFolder+ " alreay exists remove it before continute")
else:
	for detname in os.listdir(detPath):
		dirFolder = os.path.join(todayDataFolder, detname).rstrip('\n')
		detPc = os.path.join(detPath,detname)			
		fh = open(detPc)
		for sysname in fh:
			detFolder = os.path.join(currentData, sysname).rstrip('\n')	
			if os.path.exists(detFolder):
				if len(os.listdir(detFolder)) == 0:
					#remove empty Dir
					os.rmdir(detFolder)
				else:
					# if not empty now create dir folder for PC
					if not os.path.exists(dirFolder):os.makedirs(dirFolder)												
					for file in os.listdir(detFolder):
						#check for .txt file
						if file.endswith(".txt"):
							if not os.path.exists(key_log_folder_name):os.makedirs(key_log_folder_name)
							x = os.path.join(detFolder,file)
							y = os.path.join(key_log_folder_name+"/"+file)
							shutil.move(x,y)
					#move folder to new NAS location
					shutil.move(detFolder, dirFolder)
	if os.path.exists(todayDataFolder):						
		shutil.copytree(todayDataFolder, data_folder_name)				