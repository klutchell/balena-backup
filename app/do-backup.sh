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

init_backend "${backend}"
init_location "${backup_id}" "${uuid}" "${backend}" "${cache}"

/usr/bin/autorestic --ci --verbose --config "${config}" check

/usr/bin/autorestic --ci --verbose --config "${config}" backup --location "${backup_id}"
