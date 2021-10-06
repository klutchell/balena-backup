#!/usr/bin/env bash

set -eu

# shellcheck disable=SC1091
source /usr/src/app/storage.sh

# shellcheck disable=SC1091
source /usr/src/app/helpers.sh

uuid="${1}"
shift || true
tags="${1:-}"
shift || true
repository="${1:-$RESTIC_REPOSITORY}"
shift || true

request_lock

# shellcheck disable=SC1091
source /usr/src/app/ssh-agent.sh

# shellcheck disable=SC1091
source /usr/src/app/balena-api.sh

# shellcheck disable=SC1091
source /usr/src/app/rsync-shell.sh "${uuid}" "$(get_username)"

cache="${CACHE_ROOT}/${uuid}"

mkdir -p "${cache}"
mkdir -p "${repository}"

dry_run=()
if truthy "${DRY_RUN:-}"
then
    info "Starting dry-run of ${uuid} with tags '${tags}'..."
    dry_run=(--dry-run)
else
    info "Starting backup of ${uuid} with tags '${tags}'..."
fi

restic snapshots 1>/dev/null 2>&1 || restic init

rsync -avz "${uuid}:/${DEVICE_DATA_ROOT}/" "${cache}/" --delete "${dry_run[@]}"
# TODO: wait until this PR is in an official release https://github.com/restic/restic/pull/3300
truthy "${DRY_RUN:-}" || restic -r "${repository}" --verbose backup "${cache}" --host "${uuid}" --tag "${tags}" "${@}" 1>/dev/stdout 2>/dev/stderr

if truthy "${DRY_RUN:-}"
then
    info "Completed dry-run of ${uuid} with tags '${tags}'..."
else
    info "Completed backup of ${uuid} with tags '${tags}'..."
fi

release_lock
