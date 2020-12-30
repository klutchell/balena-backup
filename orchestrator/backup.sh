#!/bin/bash

# helper script to form a duplicity command
# and and call execute.sh after setting
# BACKUP_VOLUMES and MOUNT_MODE in the env

set -eu

UUID="${1}"
test -n "${UUID}"

# shellcheck disable=SC1091
source /usr/src/app/balena-api.sh

ret="$(get_device_tag_value "${UUID}" backupUrl)"
[ -n "${ret}" ] && BACKUP_URL="${ret}"

ret="$(get_device_tag_value "${UUID}" backupVolumes)"
[ -n "${ret}" ] && BACKUP_VOLUMES="${ret}"

# subsistute env vars that may be in the backup url
BACKUP_URL="$(eval echo "${BACKUP_URL}")"

cmd="--verbosity 9 --allow-source-mismatch /volumes ${BACKUP_URL}"

# assume read-only for backups
MOUNT_MODE="ro"

export BACKUP_VOLUMES MOUNT_MODE

/usr/src/app/execute.sh "${UUID}" "${cmd}"
