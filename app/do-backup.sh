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

if [ -z "${backend_id}" ]
then
    echo "Failed to resolve a unique backend for this type & path!"
    exit 1
fi

set_backend_config "${backend_id}" "${backend_type}" "${backend_path}"
set_location_config "${backup_id}" "${uuid}" "${cache}" "${backend_id}"

config="$(get_backend_config "${backend_id}")"

mkdir -p "${cache}"

/usr/bin/autorestic --ci --verbose --config "${config}" check

/usr/bin/autorestic --ci --verbose --config "${config}" backup --location "${backup_id}"
