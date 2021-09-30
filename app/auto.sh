#!/usr/bin/env bash

set -eu

# shellcheck disable=SC1091
source /usr/src/app/.env

# shellcheck disable=SC1091
source /usr/src/app/balena-api.sh

# shellcheck disable=SC1091
source /usr/src/app/functions.sh

backend="${1:-$BACKEND_NAME}"
config="$(backend_config "${backend}")"

init_backend "${backend}"
locations=()

for uuid in $(get_online_uuids_with_tag_key backup_id)
do
    backup_id="$(get_uuid_tag_value "${uuid}" backup_id)"
    if [ "${backup_id}" != "$(sanitize "${backup_id}")" ]
    then
        echo "ERROR: Detected special characters in backup_id '${backup_id}'!"
        echo "${uuid}"
        echo "Skipping this device..."
        continue
    fi

    uuids_with_tag_value="$(get_all_uuids_with_tag_value backup_id "${backup_id}")"
    if [ "$(echo "${uuids_with_tag_value}" | wc -l)" -gt 1 ]
    then
        echo "ERROR: Detected multiple online devices with backup_id '${backup_id}'!"
        echo "${uuids_with_tag_value}"
        echo "Skipping these devices..."
        continue
    fi

    cache="${CACHE_ROOT}/${backup_id}"

    init_location "${backup_id}" "${uuid}" "${backend}" "${cache}"

    locations+=(-l)
    locations+=("${backup_id}")
done

/usr/bin/autorestic --ci --verbose --config "${config}" check

if ! truthy "${DRY_RUN:-}"
then
    /usr/bin/autorestic --ci --verbose --config "${config}" backup "${locations[@]}"
fi
