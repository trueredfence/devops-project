#!/usr/bin/python3
import os
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
nas_pass="Bmt28R$e*3"
os.system("sudo mount -t cifs -o file_mode=0777,dir_mode=0777,vers=3.0,username=analysis,password='"+nas_pass+"' //192.168.12.57/analysis/DATA/X_RAY_DATA/ /home/netmachine/Desktop/Data")
#if not os.path.exists(os.path.join(mountPoint,current_year,"Month")):os.makedirs(os.path.join(mountPoint,current_year,"Month"))
#os.system('mv '+currentData+' '+os.path.join(mountPoint,current_year)+'')
#shutil.move(currentData, os.path.join(mountPoint,current_year,"Month"))

