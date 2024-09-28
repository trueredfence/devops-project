#!/bin/bash
PATH=$PATH:/bin:/usr/bin:/usr/sbin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export PATH
DATA_LOC=/home/data
let count=0
echo "Choose Option";
echo "1. For RIMS";
echo "2. For XRay";
echo "3. For Inhouse";
read CHOICE
LOC="";
echo -n "Your selection is";
case $CHOICE in
    1) 
    LOC=${DATA_LOC}/RIMS/PC/**/**/**/*;
    echo " XRayRIMS";
    ;;
    2)
    LOC=${DATA_LOC}/DATA/X_RAY_DATA/**/**/**/*;
    echo " XRay";
    ;;
    *)
    echo " not valid ";
    exit 9999;
    ;;
esac
for dir in $LOC;
do
    for f in "$dir"/*;
    do
        if [[ -f $f ]]; then
            let count=count+1
        fi   
        if [[ -d "$LOC" ]]; then
            echo $LOC
        fi     
    done  
    IFS='/'
    read -a filepath <<< "$dir"
    AGENT_DATE=${filepath[6]}
    AGENT_NAME=${dir##*/}
    DTE_SEC=${filepath[7]}
    if [[ count -gt 1 ]];then
        if [[ $(echo $AGENT_DATE | grep "Data as on" | wc -l) -ge 1 ]];then
		    echo $AGENT_NAME "[" $DTE_SEC "]" $AGENT_DATE "no of messages pending" $count
            echo $AGENT_NAME "[" $DTE_SEC "]" $AGENT_DATE "no of messages pending" $count >> output.txt
	    fi
    fi  
    let count=0;
done
