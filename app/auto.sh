#!/usr/bin/env bash

set -eu

# shellcheck disable=SC1091
source /usr/src/app/.env

# shellcheck disable=SC1091
source /usr/src/app/balena-api.sh

# shellcheck disable=SC1091
source /usr/src/app/functions.sh

lock_file="/config/.autorestic.lock.yml"
if [ -f "${lock_file}" ] && truthy "$(yq e '.running' "${lock_file}")"
then
    echo "Another instance is already running!"
    echo "If this seems like an error, try deleting ${lock_file} or restarting the container."
    exit 1
fi

backend_type="${1:-$BACKEND_TYPE}"
backend_path="${2:-$BACKEND_PATH}"

backend_id="$(get_backend_id "${backend_type}" "${backend_path}")"

if [ -z "${backend_id}" ]
then
    echo "Failed to resolve a unique backend for this type & path!"
    exit 1
fi

set_backend_config "${backend_id}" "${backend_type}" "${backend_path}"

config="$(get_backend_config "${backend_id}")"

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

    set_location_config "${backup_id}" "${uuid}" "${cache}" "${backend_id}"

    mkdir -p "${cache}"

    locations+=(-l)
    locations+=("${backup_id}")
done

export RESTIC_CACHE_DIR

/usr/bin/autorestic --ci --verbose --config "${config}" check || exit 1

if ! truthy "${DRY_RUN:-}"
then
    /usr/bin/autorestic --ci --verbose --config "${config}" backup "${locations[@]}"
fi
