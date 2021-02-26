# bitwarden_rs-local-backup
Create encrypted backups of your Bitwarden_RS database locally every 6 hours. Maintains backups from the last 30 days on the host, in the cloud the backups are *not* cleared. 

The encryption is only for guarding against illegal access on other machines. The machine that makes the backup has the key and thus can alway decrypt it, next to the fact it also has the unencrypted source of the backup. 

**NOTE:** This does **not** mean that your passwords are unencrypted! They are encrypted by the Bitwarden client and are stored encrypted on the server. This only encrypts the configuration of bitwarden_rs. 

**Important:** Make sure to securely store your backup encryption key somewhere outside your digital vault. Losing your backup encryption key will make all backups useless.

## How to Use
After configuration: `docker-compose up -d` in the folder where this is checked out. Create a .env file with the following variables:
```bash
# Backup dir on the host
HOST_BACKUP_DIR=/data/bitwarden/backups
# Data dir on the host
HOST_DATA_DIR=/data/bitwarden
# Location of the rclone config on the host.
HOST_RCLONE_CONFIG=/data/bitwarden/backups/rclone.conf
# Encryption password
BACKUP_ENCRYPTION_KEY=somepassword
# Rclone destinations for the backup, pipe (|) separted values.
RCLONE_DESTINATIONS=cloudservice1:/backup|service2:/bw/backup
```
### Rclone configuration
Read the [documentation](https://rclone.org/docs), or just try to configure `rclone`. It has great onscreen instructions. 
```bash
docker exec -it bw-backup-worker /bin/bash
rclone config
# follow instructions of rclone
``` 
Ensure that the rclone config is stored on the host! It is mounted in the container from `HOST_RCLONE_CONFIG`.

## Stop, update, shutdown
In the checkout folder do this:
```bash
docker-compose down # Shutdown
docker-compose build # Rebuild changes
docker-compose up -d # Start again (instantly creating backup)
```

## Decrypting Backups
Required: `-pbkdf2` option in openssl. Available since openssl 1.1.1, which is installed in the docker image and may not be available on the default repository on your distribution.
1. `docker exec -it bw-backup-worker /bin/bash`
2. `mkdir -p /backups/restore && openssl enc -d -aes256 -salt -pbkdf2 -pass pass:BACKUP_ENCRYPTION_KEY -in /backups/DESIRED_BACKUP_NAME.tar.gz | tar xz -C /backups/restore`
3. Grab your `db.sqlite3` and other files from `HOST_BACKUP_DIR/restore/`