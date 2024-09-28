#!/bin/bash
PATH=$PATH:/bin:/usr/bin:/usr/sbin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export PATH
rm -rf /var/www/html/cnc/App/tmpm/reports/output.txt
DATA_LOC=/home/data
let count=0 
XRAY=${DATA_LOC}/DATA/X_RAY_DATA/**/**/**/*;
#xRAY
for dir in $XRAY;
do    
    echo $dir."--"
    if [ -d "$dir" ]; then
        let count=count+`find "$dir" -type f | wc -l`       
    fi
    IFS='/'
    read -a filepath <<< "$dir"    
    if [[ count -ge 1 ]];then
        if [[ $(echo ${filepath[6]} | grep "Data as on" | wc -l) -ge 1 ]];then                        
            echo ${dir##*/} "[" ${filepath[7]} "]" ${filepath[6]} "no of messages pending" $count >> /var/www/html/cnc/App/tmpm/reports/output.txt
	    fi
    fi  
    let count=0;
done