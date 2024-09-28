#!/bin/bash
set pass Hj78%^\$dfh#@@123njdyHG
spawn ssh root@81.17.28.123 ls -lth /var/wxw/sundays | grep 'Oct 30' | awk '{print \$NF}'
expect "*?assword*"
send -- "$pass\r"
interact