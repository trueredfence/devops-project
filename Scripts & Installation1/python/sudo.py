#!/usr/bin/python3
import os
import sys
#import subprocess
from datetime import datetime
import shutil
from subprocess import call    

pwd="my password"
cmd=' ls'
print('echo {} | sudo -S {}'.format(pwd, cmd))
call('echo {} | sudo -S {}'.format("Admin@4680!", cmd), shell=True)