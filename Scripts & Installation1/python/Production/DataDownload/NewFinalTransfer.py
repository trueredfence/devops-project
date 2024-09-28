#!/usr/bin/python3
import os
import re
import sys
import subprocess
from datetime import datetime
import shutil
import time

currentDataFolder = "Data_as_on_"+str(datetime.today().strftime('%d %b %Y'))
currentKeylogFolder = "Keylog_as_on_"+str(datetime.today().strftime('%d %b %Y'))
currentYear = str(datetime.today().strftime('%Y'))
currentMonth = str(datetime.today().strftime('%h %y'))
DTE_FOLDER = 'dtes/'
DATA_FOLDER = 'Data/'
NO_OF_TGT = 0

CRED = '\033[91m'
CEND = '\033[0m'
OKGREEN = '\033[92m'
######### NAS SETTING #############
MOUNT_POINT=os.path.join(os.path.expanduser('~'), 'Documents', 'Data')
NAS_PASS="Mks*56Jdn#67" #NAS Password
SYSTEM_PASS = "admin@4680!" #Root Password
####################################


def validate():	
	if not os.path.exists(DTE_FOLDER):sys.exit(CRED+"dtes folder is not available in current location"+CEND)
	if not os.path.exists(DATA_FOLDER):sys.exit(CRED+"Data folder is not available in current location"+CEND)
	if (len(os.listdir(DATA_FOLDER)) == 0):sys.exit(CRED+"Data folder is empty"+CEND)
	if not SYSTEM_PASS:sys.exit(CRED+"System Root Password required to run this script as argument"+CEND)

def sanitizeString(reqString):
	if(not(reqString and reqString.strip())):
		return False
	else:	
		return reqString.rstrip('\n')
		
def moveFiles():
	validate()
	noOfPC = 0
	for dteFile in os.listdir(DTE_FOLDER):
		getSysName = os.path.join(DTE_FOLDER,dteFile)		
		fh = open(getSysName)
		for sysName in fh:	
			s = sanitizeString(sysName)						
			if s is not False:	
				sysFolder = os.path.join(DATA_FOLDER, s)			
				if os.path.exists(sysFolder): # If found in Data folder
					if len(os.listdir(sysFolder)) == 0: # if System folder is empty
						shutil.rmtree(sysFolder, ignore_errors=True)
					else:
						NewDataFolder = os.path.join(currentDataFolder,dteFile).rstrip('\n')
						if not os.path.exists(NewDataFolder):os.makedirs(NewDataFolder)
						fmLocation = os.path.join(sysFolder)
						toLocation = os.path.join(NewDataFolder,s)
						shutil.move(fmLocation, toLocation)	
						noOfPC += 1	
	mountAndMove()
	print(OKGREEN+"Total "+str(noOfPC)+" PC data transfred"+CEND)

def mountAndMove():
	print("Moving file to location")
	if not os.path.exists(MOUNT_POINT):
		print(OKGREEN+"Creating "+MOUNT_POINT+"for NAS mounting"+CEND)
		os.makedirs(MOUNT_POINT)		
	if not os.path.ismount(MOUNT_POINT):	
		print("Mounting NAS to mount point")
		mountCmd = "mount -t cifs -o file_mode=0777,dir_mode=0777,vers=3.0,username=analysis,password='"+NAS_PASS+"' //192.168.12.57/analysis/DATA/X_RAY_DATA/ "+MOUNT_POINT
		m = subprocess.call('echo {} | sudo -S {}'.format(SYSTEM_PASS, mountCmd), shell=True)
		time.sleep(2)
		if not os.path.ismount(MOUNT_POINT):
			sys.exit(CRED+"Error : "+CEND+"Unable to mount NAS copy "+OKGREEN+currentDataFolder+CEND+" to NAS manully")		
	if os.path.ismount(MOUNT_POINT):
		print("NAS mounted file are ready to move")		
		NasLoc = os.path.join(MOUNT_POINT,currentYear,currentMonth)					
		if not os.path.exists(NasLoc):			
			os.makedirs(NasLoc)
			print(OKGREEN+NasLoc+" created on NAS "+CEND)
		os.system('cp -R -v "'+currentDataFolder+'" "'+NasLoc+'"')		
		print("Moved "+OKGREEN+currentDataFolder+CEND+" folder to NAS")
		if os.path.ismount(MOUNT_POINT):
			uMountCmd = " umount "+MOUNT_POINT	
			subprocess.call('echo {} | sudo -S {}'.format(SYSTEM_PASS, uMountCmd), shell=True)			
moveFiles()