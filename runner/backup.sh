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

echo "Backing up ${uuid} as ${backup_id}..."
backup_id="${backup_id//[^[:alnum:]_-]/}"
mkdir -p "${LOCAL_BACKUPS}/${backup_id}"
rsync -avz "${uuid}:/${DATA_ROOT}/" "${LOCAL_BACKUPS}/${backup_id}/" --delete
