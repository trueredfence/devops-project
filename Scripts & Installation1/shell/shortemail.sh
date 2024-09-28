#!/bin/bash
array=(yahoo gmail 163.com qq.com 126.com sina.com tom.com hotmail live.com msn sogou.com);
echo "Please provide file name;"
read file
for i in "${array[@]}"
do
	grep -i "$i" "$file" >> "$i.txt";					
done
	egrep -iv 'yahoo|gmail|163.com|qq.com|126.com|sina.com|tom.com|hotmail|live.com|msn|sogou.com' $file >> "other.txt"
