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

echo "Stopping balena engine and balena-supervisor..."
remote_ssh_cmd systemctl stop balena balena-supervisor

echo "Syncing ${device_cache}/ to ${uuid}:/${DEVICE_DATA_ROOT}/..."

rsync -avz "${device_cache}/" "${uuid}:/${DEVICE_DATA_ROOT}/" --delete || true

echo "Restarting balena engine and balena-supervisor..."
remote_ssh_cmd systemctl start balena balena-supervisor
