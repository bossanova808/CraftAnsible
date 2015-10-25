#!/bin/sh

database="craft_projectname"
database_user="craft_projectname"
database_pass="blah"
current_date=`date +%Y-%m-%d--%H-%M`

# export database
mysqldump -u $database_user -p${database_pass} $database | gzip > ~/backups/dbbackup_${database}_${current_date}.sql.gz

# remove backups older than 7 days
find ~/backups/db* -mtime +7 -exec rm {} \;

# sync to amazon
/usr/local/bin/aws s3 sync ~/backups s3://backups.projectname.com.au --delete
