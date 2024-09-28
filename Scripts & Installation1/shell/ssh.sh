#!/bin/bash
gnome-terminal --tab -t 'S(1)' -- ssh root@146.70.20.242;
gnome-terminal --tab -t 'S(2)' -- ssh root@80.209.227.207 -p1179 ;
gnome-terminal --tab -t 'U(1)' -- ssh root@212.24.104.168;
gnome-terminal --tab -t 'U(2)' -- ssh root@51.38.85.227 -p1179;
gnome-terminal --tab -t 'Moodle' -- ssh root@45.147.228.67;
gnome-terminal --tab -t 'Reversefinal' -- ssh root@185.56.137.113 -p1179;
gnome-terminal --tab -t 'Reverseold' -- ssh root@146.70.35.151 -p1179;
