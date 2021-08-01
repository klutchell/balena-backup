#!/bin/bash

set -eu

uuid="${1}"
backup_id="${2}"

# shellcheck disable=SC1091
source /usr/src/app/ssh-agent.sh

# shellcheck disable=SC1091
source /usr/src/app/balena-api.sh

username="$(get_username)"

# shellcheck disable=SC1091
source /usr/src/app/rsync-shell.sh "${uuid}" "${username}"

echo "Stopping balena engine..."
remote_ssh_cmd systemctl stop balena.service

echo "Restoring to ${uuid} as ${backup_id}..."
backup_id="${backup_id//[^[:alnum:]_-]/}"
mkdir -p "${WORKDIR}/${backup_id}"
rsync -avz "${WORKDIR}/${backup_id}/" "${uuid}:/${DATA_ROOT}/" || true

echo "Restarting balena engine..."
remote_ssh_cmd systemctl start balena.service
