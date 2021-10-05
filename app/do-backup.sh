#!/usr/bin/env bash

set -eu

if [ -f /var/run/app.lock ]
then
    echo "Existing backup/restore in progress..."
    echo "If this seems incorrect, try deleting /var/run/app.lock or restarting the container."
    exit 1
fi

touch /var/run/app.lock

# shellcheck disable=SC1091
source /usr/src/app/.env

# shellcheck disable=SC1091
source /usr/src/app/helpers.sh

backup_id="$(sanitize "${1}")" ; shift
uuid="$(sanitize "${1}")" ; shift
repository="${1:-$RESTIC_REPOSITORY}" ; shift

# shellcheck disable=SC1091
source /usr/src/app/ssh-agent.sh

# shellcheck disable=SC1091
source /usr/src/app/balena-api.sh

# shellcheck disable=SC1091
source /usr/src/app/rsync-shell.sh "${uuid}" "$(get_username)"

cache="${CACHE_ROOT}/${backup_id}"

mkdir -p "${cache}"
mkdir -p "${repository}"

export RESTIC_CACHE_DIR

restic snapshots 1>/dev/null 2>&1 || restic init

if truthy "${DRY_RUN:-}"
then
    echo "Starting dry-run of ${backup_id}..."
    rsync -avz "${uuid}:/${DEVICE_DATA_ROOT}/" "${cache}/" --delete --dry-run
    # TODO: wait until this PR is in an official release https://github.com/restic/restic/pull/3300
    # restic --verbose -r "${repository}" backup "${cache}" --dry-run
    echo "Completed dry-run of ${backup_id}..."
else
    echo "Starting backup of ${backup_id}..."
    rsync -avz "${uuid}:/${DEVICE_DATA_ROOT}/" "${cache}/" --delete
    restic -r "${repository}" --verbose=2 backup "${cache}"
    echo "Completed backup of ${backup_id}..."
fi

rm /var/run/app.lock 2>/dev/null || true
