import os
def removeemptydir(path):
    for file in os.listdir(path):
        d = os.path.join(path, file)
        if os.path.isdir(d):
            if len(os.listdir(d)) == 0:
                os.rmdir(d)
            else:
                print(d+" is not emtpy")

removeemptydir("/home/netmachine/Documents/AV/2023/Jan/")