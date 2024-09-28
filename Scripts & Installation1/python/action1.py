#!/usr/bin/python3
import os
import sys
from datetime import datetime
import shutil

os.system("sh clear.sh")
#datetime.today().strftime('%d_%b_%Y')
print("all dte cleared")
data_folder_name="Data as on_"+str(datetime.today().strftime('%d %b %Y'))
key_log_folder_name="Keylog as on_"+str(datetime.today().strftime('%d %b %Y'))
if( os.path.exists("Data as on_"+str(datetime.today().strftime('%d %b %Y')))):
    print("Your directory 'Data as on _current_date' already exist so remove it first")    
else:
    os.mkdir("Data as on_"+str(datetime.today().strftime('%d %b %Y')))
    os.mkdir(key_log_folder_name)
    def get_filename_datetime():
        # Use current date to get a text file name.
        return "Data Transfer_" + str(datetime.today().strftime('%d %b %Y')) + ".xlsx"

    # Get full path for writing.
    name = get_filename_datetime()
    #print("NAME", name) // this is file name

    with open(name, "w") as filess:
        # Write data to file.
        filess.write("You have new look up\n")
        #f.write("WORLD\n")    
        path = 'dtes/' #this directory we read directorate
        files = []
        
        # r=root, d=directories, f = files
        for r, d, f in os.walk(path):
            for file in f:
                if '' in file:
                    files.append(os.path.join(r, file))
                    #folder_name=file.rstrip(".txt")
                    #dir_folder=os.mkdir(data_folder_name + "/" + folder_name)
                    
                    #os.mkdir(folder_name)
        for f in files:    
            fh = open(f)
            
            filess.write("\n\n*************************************directorate : "+f.strip(path)+" :\n\n")
            direct_name=f.strip(path)
            dir_folder=os.mkdir(data_folder_name + "/" + direct_name)
            direct_names=data_folder_name + "/" + direct_name
            #os.mkdir(os.path.join(data_folder_name, folder_name)
            #folder_name=f.rstrip(".txt')
            
           # print(f)
            for line in fh:
            # in python 2
            # print line
            # in python 3
                #filess.write(line)  
               # print(line)
                folder_list= os.path.join('/home/av/Desktop/XRAY/zata/', line)
               # print(folder_list)
                #filess.write(folder_list)
                dirname=folder_list.rstrip('\n')
                #CHECK_FOLDER = os.path.isdir(folder_list)
                #print(dirname)
                if(os.path.exists(dirname)):
                    if len(os.listdir(dirname)) == 0:
                        os.rmdir(dirname)
                    else:
                        filess.write(line)
                        #print(direct_names)
                        #print(dirname)
                        for file in os.listdir(dirname):
                            if file.endswith(".txt"):
                                x = os.path.join(dirname,file)
                                y = os.path.join(key_log_folder_name+"/"+file)
                                shutil.move(x,y)
                        shutil.move(dirname, direct_names)
                    
                   # print("Directory Exists1")
                #else:
                    #print("Directory does not exists")
                #here your comparisn folder
               # print(line)
                #fh.close()


