#!/usr/bin/env bash

set -eu

# shellcheck disable=SC1091
source /usr/src/app/.env

# shellcheck disable=SC1091
source /usr/src/app/functions.sh

backup_id="$(sanitize "${1}")"
uuid="$(sanitize "${2}")"
backend_type="${3:-$BACKEND_TYPE}"
backend_path="${4:-$BACKEND_PATH}"

cache="${CACHE_ROOT}/${backup_id}"

backend_id="$(get_backend_id "${backend_type}" "${backend_path}")"

# set_backend_config "${backend_id}" "${backend_type}" "${backend_path}"
# set_location_config "${backup_id}" "${uuid}" "${cache}" "${backend_id}"

config="$(get_backend_config "${backend_id}")"

/usr/bin/autorestic --ci --verbose --config "${config}" check

/usr/bin/autorestic --verbose --config "${config}" restore \
    --location "${backup_id}" \
    --from "${backend_id}" \
    --to "${cache}" \
    --force

/usr/src/app/sync-device.sh "${uuid}" "${cache}"
