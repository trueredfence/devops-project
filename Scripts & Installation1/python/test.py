import re
import os
import shutil
if not os.path.exists("screenshots"):os.makedirs("screenshots")
screenShotFile = re.compile(r'\d\d\d\d_\d\d_\d\d\d\d_\d\d_\d\d')
PATH = '/home/netmachine/Desktop/NTR/2023_05_2316_35_14.png'
mo = screenShotFile.search(PATH) == None
if mo == False:
    shutil.move(PATH, 'screenshots')