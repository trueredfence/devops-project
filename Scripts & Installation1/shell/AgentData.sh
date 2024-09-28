#!/bin/bash
PATH=$PATH:/bin:/usr/bin:/usr/sbin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export PATH
rm -rf /var/www/html/cnc/App/tmpm/reports/output.txt
rm -rf /var/www/html/cnc/App/tmpm/reports/rimsoutput.txt
DATA_LOC=/home/data
let count=0
RIMS=${DATA_LOC}/RIMS/PC/**/**/**/**/*;   
XRAY=${DATA_LOC}/DATA/X_RAY_DATA/**/**/**/*;
#xRAY
for dir in $XRAY;
do    
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

#RIMS
rimsdir=(Files screenshot)
for dir in $RIMS;
do   
    for i in "${rimsdir[@]}"; 
    do 
        FILE="$dir/$i"
        if [ -d "$FILE" ]; then                        
            let count=count+`find "$FILE" -type f | wc -l`                    
        fi        
    done;
    IFS='/'
    read -a filepath <<< "$dir"
    if [[ count -ge 1 ]];then
        if [[ $(echo ${filepath[6]} | grep "Data as on" | wc -l) -ge 1 ]];then
            echo ${filepath[8]} "[" ${filepath[7]} "] "${filepath[6]}" no of msg pending" $count >> /var/www/html/cnc/App/tmpm/reports/rimsoutput.txt
        fi;
    fi
    let count=0
done

