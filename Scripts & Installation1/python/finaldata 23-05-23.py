#!/usr/bin/python3
import os
import sys
import subprocess
from datetime import datetime
import shutil
import time

currentDataFolder = "1Data_as_on_"+str(datetime.today().strftime('%d %b %Y'))
currentKeylogFolder = "1Keylog_as_on_"+str(datetime.today().strftime('%d %b %Y'))
currentYear = str(datetime.today().strftime('%Y'))
currentMonth = str(datetime.today().strftime('%h %y'))
dteFiles = 'dtes/'
dataFolder = 'Data/'


CRED = '\033[91m'
CEND = '\033[0m'
OKGREEN = '\033[92m'
######### NAS SETTING #############
mountPoint=os.path.join(os.path.expanduser('~'), 'Documents', 'Data')
nasPass="Bmt28R$e*3" #NAS Password
SystemRootPass = "admin@4680!" #Root Password
####################################

def validate():	
	if not os.path.exists(dteFiles):sys.exit(CRED+"dtes folder is not available in current location"+CEND)
	if not os.path.exists(dataFolder):sys.exit(CRED+"Data folder is not available in current location"+CEND)
	if (len(os.listdir(dataFolder)) == 0):sys.exit(CRED+"Data folder is empty"+CEND)
	if os.path.exists(currentDataFolder):sys.exit(CRED+"Remove "+currentDataFolder+" folder"+CEND)
	if os.path.exists(currentKeylogFolder):sys.exit(CRED+"Remove "+currentKeylogFolder+" folder"+CEND)	
	if not SystemRootPass:sys.exit(CRED+"System Root Password required to run this script as argument"+CEND)
		

def moveFiles():
	validate()
	noOfPC = 0
	for detName in os.listdir(dteFiles):
		sysName = os.path.join(dteFiles,detName)			
		fh = open(sysName)		
		for sys in fh:
			sysFolder = os.path.join(dataFolder, sys).rstrip('\n')	
			if os.path.exists(sysFolder):	
				if len(os.listdir(sysFolder)) == 0:						
					os.rmdir(sysFolder)
				else:	
					for file in os.listdir(sysFolder):
						#check for .txt file
						if file.endswith(".txt"):
							if not os.path.exists(currentKeylogFolder):os.makedirs(currentKeylogFolder)
							x = os.path.join(sysFolder,file)
							y = os.path.join(currentKeylogFolder+"/"+file)
							shutil.copy(x,y)
					newFolder = os.path.join(currentDataFolder,detName).rstrip('\n')				
					if not os.path.exists(newFolder):os.makedirs(newFolder)
					shutil.move(sysFolder, newFolder)
					noOfPC += 1
	mountAndMove()
	print(OKGREEN+"Total "+str(noOfPC)+" PC data transfred"+CEND)

def mountAndMove():
	print("Moving file to lcation")
	if not os.path.exists(mountPoint):
		print(OKGREEN+"Creating "+mountPoint+"for NAS mounting"+CEND)
		os.makedirs(mountPoint)		
	if not os.path.ismount(mountPoint):	
		print("Mounting NAS to mount point")
		mountCmd = "mount -t cifs -o file_mode=0777,dir_mode=0777,vers=3.0,username=analysis,password='"+nasPass+"' //192.168.12.57/analysis/DATA/X_RAY_DATA/ "+mountPoint
		m = subprocess.call('echo {} | sudo -S {}'.format(SystemRootPass, mountCmd), shell=True)
		time.sleep(2)
		if not os.path.ismount(mountPoint):
			sys.exit(CRED+"Error : "+CEND+"Unable to mount NAS copy "+OKGREEN+currentDataFolder+CEND+" to NAS manully")		
	if os.path.ismount(mountPoint):
		print("NAS mounted file are ready to move")		
		NasLoc = os.path.join(mountPoint,currentYear,currentMonth)					
		if not os.path.exists(NasLoc):			
			os.makedirs(NasLoc)
			print(OKGREEN+NasLoc+" created on NAS "+CEND)
		os.system('cp -R -v "'+currentDataFolder+'" "'+NasLoc+'"')		
		print("Moved "+OKGREEN+currentDataFolder+CEND+" folder to NAS")
		if os.path.ismount(mountPoint):
			uMountCmd = " umount "+mountPoint	
			subprocess.call('echo {} | sudo -S {}'.format(SystemRootPass, uMountCmd), shell=True)	
moveFiles()
