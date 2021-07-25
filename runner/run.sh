#!/bin/bash

set -eu

[ "${INTERVAL}" = "off" ] && { echo "Interval is off, disabling automatic backups..." ; sleep infinity ; }

# shellcheck disable=SC1091
source /usr/src/app/balena-api.sh

while :
do
    echo "Getting online devices with tag 'backup_id'..."
    uuids="$(get_online_uuids_with_tag_key backup_id)"
    echo "${uuids}"
    for uuid in ${uuids}
    do
        backup_id="$(get_uuid_tag_value "${uuid}" backup_id)"
        /usr/src/app/backup.sh "${uuid}" "${backup_id}"
    done
    echo "Sleeping for ${INTERVAL}..."
    sleep "${INTERVAL}"
done
