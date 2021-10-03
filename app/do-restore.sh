#!/usr/bin/env bash

set -eu

# shellcheck disable=SC1091
source /usr/src/app/.env

# shellcheck disable=SC1091
source /usr/src/app/functions.sh

backup_id="$(sanitize "${1}")"
uuid="$(sanitize "${2}")"
backend="${3:-$BACKEND_NAME}"

config="$(backend_config "${backend}")"
cache="${CACHE_ROOT}/${backup_id}"

/usr/bin/autorestic --ci --verbose --config "${config}" check

/usr/bin/autorestic --verbose --config "${config}" restore \
    --location "${backup_id}" \
    --from "${backend}" \
    --to "${cache}" \
    --force

/usr/src/app/sync-device.sh "${uuid}" "${cache}"
