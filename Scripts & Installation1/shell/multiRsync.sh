#!/bin/bash
REMOTE_PC=`ssh root@51.38.85.227 -p 1179 'du -h /home/data/'`
echo REMOTE_PC
#gnome-terminal --tab -t 'S(1)' -- ssh root@146.70.20.242;