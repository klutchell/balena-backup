#!/bin/bash

set -eu

test -n "${CLI_API_KEY}"

[ -d "/var/spool/cron/crontabs" ] || mkdir -p /var/spool/cron/crontabs

cat > /var/spool/cron/crontabs/root << EOF
0 */1 * * * echo "hello world!"
EOF

# shellcheck disable=SC1091
source /usr/src/app/balena-api.sh

# iterate over each device in the array and create a crontab entry
for uuid in $(get_online_devices_by_tag backupEnabled true)
do
    # use the schedule defined by a tag if it exists
    ret="$(get_device_tag_value "${uuid}" backupSchedule)"
    [ -n "${ret}" ] && BACKUP_SCHEDULE="${ret}"

    echo "${BACKUP_SCHEDULE} /usr/src/app/backup.sh \"${uuid}\" | tee /var/log/${uuid}.log" >> /var/spool/cron/crontabs/root
done

cat /var/spool/cron/crontabs/root

_term() { 
    kill -TERM "${CRON_PID}" 2>/dev/null
}

trap _term SIGINT SIGTERM

# execute cron in the background with logging to stdout
exec busybox crond -f -l 0 -L /dev/stdout &

# then attach to it so we can trap SIGINT and SIGKILL messages
CRON_PID="$!"
wait "${CRON_PID}"
