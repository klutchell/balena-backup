#!/usr/bin/env bash

set -eu

uuid="${1}"
shift || true
tags="${1:-}"
shift || true
repository="${1:-$RESTIC_REPOSITORY}"
shift || true

# shellcheck disable=SC1091
source /usr/src/app/helpers.sh

request_lock
trap release_lock EXIT

# shellcheck disable=SC1091
source /usr/src/app/ssh-agent.sh

# shellcheck disable=SC1091
source /usr/src/app/balena-api.sh

username="$(get_username)"

cache="${CACHE_ROOT}/${uuid}"

mkdir -p "${cache}"
mkdir -p "${repository}"

dry_run=()
truthy "${DRY_RUN:-}" && dry_run=(--dry-run)

info "Starting backup..."
debug " uuid       = ${uuid}"
debug " tags       = ${tags}"
debug " repository = ${repository}"
debug " dry-run    = ${DRY_RUN:-}"

/usr/bin/restic -r "${repository}" snapshots 1>/dev/null 2>&1 || /usr/bin/restic -r "${repository}" init

info "Syncing files from ${uuid}:/${DEVICE_DATA_ROOT}/ to ${cache}/..."

/usr/bin/rsync -avz -e "$(rsync_rsh "${username}" "${uuid}")" "${uuid}:/${DEVICE_DATA_ROOT}/" "${cache}/" --delete "${dry_run[@]}"
 
# TODO: append dry_run when feature is released
# https://github.com/restic/restic/pull/3300
if ! truthy "${DRY_RUN:-}"
then
    info "Creating snapshot for host ${uuid} with tags '${tags}'..."
    /usr/bin/restic -r "${repository}" backup "${cache}" --host "${uuid}" --tag "${tags}"
fi

info "Completed backup!"
