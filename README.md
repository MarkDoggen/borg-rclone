# Borg + Rclone backup
Docker image to backup to a local Borg repository and then sync the Borg repository to any destination supported by Rclone. Inspired by https://github.com/mannkind/borg-rclone-autobackup, with some added features:
* Before backup hook, to run any command before the backup is created. Can be used in combination with the included ```pg_dump``` command to backup a Postgres database to be included in the backup.
* Pushover notification on success / failure.

## How to use
This example uses all environment variables. See below which variables are optional.

```
docker run \
    -v /home:/home \
    -v /backups:/backups \
    -e BACKUP_NAME="mybackup" \
    -e BACKUP_SCHEDULE="0 2 * * *" \
    -e BACKUP_ARGUMENTS="/home --exclude /home/.cache/" \
    -e BORG_PASSPHRASE="topsecret" \
    -e BEFORE_BACKUP="echo Running backup" \
    -e RCLONE_CONF="[drive]\ntype=drive\nscope=drive.file\ntoken={}" \
    -e RCLONE_DESTINATION="drive:" \
    -e PRUNE_ARGUMENTS="--keep-daily 7 --keep-weekly 4 --keep-monthly 6" \
    -e PUSHOVER_APP_TOKEN="12345" \
    -e PUSHOVER_USER_KEY="12345" \
    -e PING_SUCCESS="https://my.webhook" \
    markdoggen/borg-rclone
```

##  Configuration
The following environment variables are mandatory:
* ```BACKUP_NAME``` name of the backup.
* ```BACKUP_ARGUMENTS``` arguments to be passed to the ```borg create``` command. See [https://borgbackup.readthedocs.io/en/stable/usage/create.html](https://borgbackup.readthedocs.io/en/stable/usage/create.html)
* ```BORG_PASSPHRASE``` passphrase to be used for encryption of the backup.
* ```RCLONE_CONF``` contents of ```rclone.conf```. If set, contents will be written to ```/borg-rclone/rclone.conf``` and used as configuration file for Rclone.  (note: instead of passing ```RCLONE_CONF```, you can also mount your configuration file to ```/borg-rclone/rclone.conf```). 
* ```RCLONE_DESTINATION``` destination path to sync the backup to. Defaults to ```drive:``` See [https://rclone.org/docs/](https://rclone.org/docs/)

The following environment variables are optional:
* ```BACKUP_SCHEDULE``` cron schedule for the backup. Defaults to ```0 0 * * *``` (daily backups at midnight). 
* ```BEFORE_BACKUP``` command(s) to be run before Borg runs ```backup create```.
* ```PRUNE_ARGUMENTS``` arguments to be passed to the ```borg prune``` command. See [https://borgbackup.readthedocs.io/en/stable/usage/prune.html](https://borgbackup.readthedocs.io/en/stable/usage/prune.html). Backup pruning is disabled if this variable is omitted.
* ```PUSHOVER_APP_TOKEN``` and ```PUSHOVER_USER_KEY``` can be set to be notified of the backup result.
* ```PING_SUCCESS``` webhook that will be invoked when the backup has successfully ran.
