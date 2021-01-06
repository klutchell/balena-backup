#!/bin/bash

set -eu

mkdir -p /var/spool/cron/crontabs

array=("*/10 * * * * /usr/src/app/update-crontab.sh")

# shellcheck disable=SC1091
source /usr/src/app/balena-api.sh

# iterate over each device in the array and create a crontab entry
for uuid in $(get_online_devices_by_tag backupEnabled true)
do
    # use the schedule defined by a tag if it exists
    ret="$(get_device_tag_value "${uuid}" backupSchedule)"

    if [ -n "${ret}" ]
    then
        array+=("${ret} /usr/src/app/backup-device.sh ${uuid}")
    else
        array+=("${BACKUP_SCHEDULE} /usr/src/app/backup-device.sh ${uuid}")
    fi
done

crontab="$(printf '%s\n' "${array[@]}")"

if [ ! -f "/var/spool/cron/crontabs/root" ] || [ "${crontab}" != "$(</var/spool/cron/crontabs/root)" ]
then
    echo "${crontab}" > /var/spool/cron/crontabs/root
    cat /var/spool/cron/crontabs/root
fi
