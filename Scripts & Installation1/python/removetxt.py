import os, shutil
def removeemptydir(path):
    for file in os.listdir(path):
        d = os.path.join(path, file)
        if os.path.isdir(d):
            if len(os.listdir(d)) == 0:
                os.rmdir(d)
            else:
                for file in os.listdir(d):
                   if file.endswith(".txt"):                        
                        x = os.path.join(d, file)
                        y = os.path.join(d, "keylog/"+file)
                        #print(x)
                        shutil.move(x,y)

removeemptydir("/run/media/netmachine/Safe/X-Ray/VMShare/Current Working/")