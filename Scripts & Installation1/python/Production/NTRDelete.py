#!/usr/bin/python3
# Nas mount COmmand
# sudo mount -t cifs -o file_mode=0777,dir_mode=0777,vers=3.0,username=analysis,password='Bmt28R$e*3' //192.168.12.57/analysis/DATA/VPS_DATA/ /home/netmachine/Documents/Data


import os
import sys
import subprocess
import shutil
from datetime import date
from dateutil.relativedelta import relativedelta
CRED = '\033[91m'
CEND = '\033[0m'
OKGREEN = '\033[92m'

# Chagne this
PATH_FOR_NTR = '/home/netmachine/Documents/Data'

def CheckNTR():
	countNTR = 0
	countEmpty = 0	
	currentMonth = "/"+str(date.today().strftime('%h %y'))+"/"
	pMonth = date.today() - relativedelta(months=1)
	pastDate = "/"+str(pMonth.strftime('%h %y'))+"/"
	rootdir = PATH_FOR_NTR
	for rootdir, dirs, files in os.walk(rootdir):		
		for subdir in dirs:
			PATH = os.path.join(rootdir, subdir)
			if currentMonth in PATH or pastDate in PATH:
				print(OKGREEN+"Escaping Directory :"+CEND +currentMonth +" "+pastDate+"")
				continue
			if len(os.listdir(PATH)) == 0:
				print(CRED+"Empty Dir Deleting Path:"+CEND+PATH)
				countEmpty += 1
				shutil.rmtree(PATH, ignore_errors=True)
			if subdir == "NTR" or subdir == "ntr" or subdir == "Ntr" or subdir == "oss NTR":
				countNTR += 1
				shutil.rmtree(PATH, ignore_errors=True)
				print(CRED+"NTR Deleting Path:"+CEND+PATH)
	print("Total "+str(countNTR)+" NTR folder deleted from NAS")
	print("Total "+str(countEmpty)+" Empty folder deleted from NAS")
	if countEmpty != 0 or countNTR != 0:
		CheckNTR()
	    	   
CheckNTR()