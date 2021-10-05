#!/usr/bin/env bash

set -eu

# shellcheck disable=SC1091
source /usr/src/app/.env

# shellcheck disable=SC1091
source /usr/src/app/balena-api.sh

for uuid in $(get_online_uuids_with_tag_key backup_tags)
do
    backup_tags="$(get_uuid_tag_value "${uuid}" backup_tags)"

    DRY_RUN="${DRY_RUN:-}" /usr/src/app/do-backup.sh "${uuid}" "${backup_tags}" "${RESTIC_REPOSITORY}"
done
