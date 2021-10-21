#!/usr/bin/env bash

set -eu

# shellcheck disable=SC1091
source /usr/src/app/helpers.sh

# shellcheck disable=SC1091
source /usr/src/app/balena-api.sh

for uuid in $(get_online_uuids_with_tag_key backup_tags)
do
    [ "${uuid}" = "${BALENA_DEVICE_UUID:-}" ] && continue
    
    backup_tags="$(get_uuid_tag_value "${uuid}" backup_tags)"

    DRY_RUN="${DRY_RUN:-}" /usr/src/app/do-backup.sh "${uuid}" "${backup_tags}" "${RESTIC_REPOSITORY}" || continue
done

truthy "${DRY_RUN:-}" || /usr/bin/restic -r "${RESTIC_REPOSITORY}" forget --prune --keep-hourly 24 --keep-daily 7 --keep-weekly 5 --keep-monthly 12 --group-by tag | cat
