#!/bin/sh
if [[ -z "${BACKUP_SCHEDULE}" ]]; then
	BACKUP_SCHEDULE="0 0 * * *"
fi
echo "$BACKUP_SCHEDULE /borg-rclone/backup.sh" > /etc/crontabs/root

/usr/sbin/crond -l 8 -f
