#!/usr/bin/env bash

set -eu

# shellcheck disable=SC1091
source /usr/src/app/.env

# shellcheck disable=SC1091
source /usr/src/app/balena-api.sh

for uuid in $(get_online_uuids_with_tag_key backup_id)
do
    backup_id="$(get_uuid_tag_value "${uuid}" backup_id)"
    uuids_with_tag_value="$(get_all_uuids_with_tag_value backup_id "${backup_id}")"

    if [ "$(echo "${uuids_with_tag_value}" | wc -l)" -gt 1 ]
    then
        echo "ERROR: Detected multiple online devices with backup_id '${backup_id}'!"
        echo "${uuids_with_tag_value}"
        echo "Skipping these devices..."
        continue
    fi

    DRY_RUN="${DRY_RUN:-}" /usr/src/app/do-backup.sh "${backup_id}" "${uuid}" "${RESTIC_REPOSITORY}"
done
