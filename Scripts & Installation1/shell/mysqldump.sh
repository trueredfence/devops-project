Mysql Dump
------------
backup_path="/home/data/backups/dumpsql/"
now="$(date +'%d-%b-%Y')"
fname="$backup_path$now.gz"
mysqldump --user=root --password=Admin@4680 --host=localhost CNC | gzip > $fname
find $backup_path -type f -mtime +7 -name '*.gz' -exec rm -- {} \;
find $backup_path -type f -mtime +7 -name '*.gz' -delete;
find $backup_path -type f -mtime +7 -name '*.gz' | xargs rm -f

Data-Backup
-------------

#!/bin/bash
if (( $(ps ax | grep rsync | grep mount | wc -l) < 2 )); then /usr/bin/rsync -azh /var/www/html/cnc/App/tmpm/ /home/data/; fi;
~
