#!/usr/bin/env bash

set -eu

uuid="${1}"
device_cache="${2}"

# shellcheck disable=SC1091
source /usr/src/app/ssh-agent.sh

# shellcheck disable=SC1091
source /usr/src/app/balena-api.sh

username="$(get_username)"

# shellcheck disable=SC1091
source /usr/src/app/rsync-shell.sh "${uuid}" "${username}"

mkdir -p "${device_cache}"

echo "Syncing ${uuid}:/${DEVICE_DATA_ROOT}/ to ${device_cache}/..."

rsync -avz "${uuid}:/${DEVICE_DATA_ROOT}/" "${device_cache}/" --delete
