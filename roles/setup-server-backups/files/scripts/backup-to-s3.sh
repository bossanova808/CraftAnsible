#!/bin/sh

site="Whatever"
database="craft_whatever"
database_user="craft_whatever"
database_pass="whatever"
current_date=`date +%Y-%m-%d--%H-%M`

# export database
mysqldump -u $database_user -p${database_pass} $database | gzip > ~/backups/db_backup_${database}_${current_date}.sql.gz

# zip up lets encrypt folder (Need to be root)
tar -czf ~/backups/certs_backup_${current_date}.tar.gz /etc/letsencrypt  

# remove db backups older than 14 days
find ~/backups/db* -mtime +14 -exec rm {} \;

# remove cert backups older than 14 days
find ~/backups/certs* -mtime +14 -exec rm {} \;

# sync to amazon
/usr/local/bin/aws s3 sync ~/backups s3://backups.whatever.com --delete
