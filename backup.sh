log(){
	title="Backup: $BACKUP_NAME"
	message="$@"
	echo $message
	if [ -n "$PUSHOVER_APP_TOKEN" ] && [ -n "$PUSHOVER_USER_KEY" ]; then
		curl -s --form-string "token=$PUSHOVER_APP_TOKEN" --form-string "user=$PUSHOVER_USER_KEY" --form-string "title=$title" --form-string "message=$message" https://api.pushover.net/1/messages.json > /dev/null
	fi
}

ping_failure(){
	if [[ "${PING_FAILURE}" ]]; then
		curl -s $PING_FAILURE > /dev/null
	fi
}

ping_success(){
	if [[ "${PING_SUCCESS}" ]]; then
		curl -s $PING_SUCCESS > /dev/null
	fi
}

if [ -z "$BORG_PASSPHRASE" ] || [ -z "$BACKUP_NAME" ] || [ -z "$BACKUP_ARGUMENTS" ]; then
	echo 'Please specify $BORG_PASSPHRASE, $BACKUP_NAME and $BACKUP_ARGUMENTS'
	exit 1
fi

export BORG_REPO="/backups/$BACKUP_NAME"

if [[ ! -d "$BORG_REPO" ]]; then
    echo "Initializing repository"
    mkdir -p "$BORG_REPO"
    borg init --encryption=repokey
fi

if [[ "${BEFORE_BACKUP}" ]]; then
	echo "Running before backup hook"
	/bin/sh -c "$BEFORE_BACKUP"
fi

borg create --verbose --filter AME --list --stats --show-rc --exclude-caches $BORG_REPO::'{now}' $BACKUP_ARGUMENTS --exclude /backups
backup_exit=$?

if [[ "${PRUNE_ARGUMENTS}" ]]; then
	borg prune --list --show-rc $PRUNE_ARGUMENTS
	prune_exit=$?
else
	prune_exit=0
fi

if [[ "${RCLONE_CONF}" ]]; then
	echo -e $RCLONE_CONF > /app/rclone.conf
fi

if [[ -z "${RCLONE_DESTINATION}" ]]; then
	RCLONE_DESTINATION="drive:"
else
	RCLONE_DESTINATION="${RCLONE_DESTINATION}"
fi

rclone --config=/app/rclone.conf sync --verbose $BORG_REPO $RCLONE_DESTINATION
rclone_exit=$?

if [ ${backup_exit} -ne 0 ]; then
    log "Borg backup command failed"
    ping_failure
elif [ ${prune_exit} -ne 0 ]; then
	log "Borg prune command failed"
	ping_failure
elif [ ${rclone_exit} -ne 0 ]; then
	log "Rclone command failed"
	ping_failure
else
	log "Backup ran successfully"
	ping_success
fi
