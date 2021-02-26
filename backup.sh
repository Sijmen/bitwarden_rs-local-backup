#!/bin/sh
set -ex
# rm any backups older than 30 days
find /backups/* -mtime +30 -exec rm {} \;

# create backup filename
BACKUP_FILE="db.sqlite3_$(date "+%F-%H%M%S")"

# use sqlite3 to create backup (avoids corruption if db write in progress)
sqlite3 /data/db.sqlite3 ".backup '/tmp/db.sqlite3'"

# Copy other (optional) data
cp /data/attachments /tmp/attachments || true
cp /data/rsa_key* /tmp/ || true
cp /data/config.json /tmp/ || true


# tar up everything in /tmp and encrypt with openssl and encryption key
cd /tmp
tar -czf - * | openssl enc -e -aes256 -salt -pbkdf2 -pass pass:${BACKUP_ENCRYPTION_KEY} -out /backups/${BACKUP_FILE}.tar.gz
cd -

# cleanup tmp folder
rm -rf /tmp/*

# Copy to cloud 
# TODO make destination configurable.
upload() {
    local IFS='|' 
    destinations="$RCLONE_DESTINATIONS"
    for destination in ${destinations}; do
        rclone -vv --no-check-dest copy "/backups/${BACKUP_FILE}.tar.gz" "${destination}"
    done
}
# Copy to cloud 
upload