#!/usr/bin/env bash

set -eu

target_uuid="${1}"
shift || true
source_uuid="${1:-$target_uuid}"
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

cache="${CACHE_ROOT}/${target_uuid}"

mkdir -p "${cache}"
mkdir -p "${repository}"

dry_run=()
truthy "${DRY_RUN:-}" && dry_run=(--dry-run)

info "Starting restore..."
debug " source     = ${source_uuid}"
debug " target     = ${target_uuid}"
debug " repository = ${repository}"
debug " dry-run    = ${DRY_RUN:-}"

if ! truthy "${DRY_RUN:-}"
then
    info "Stopping balena engine and balena-supervisor..."
    exec_ssh_cmd "${username}" "${target_uuid}" systemctl stop balena balena-supervisor
fi

# TODO: append dry_run when feature is released
# https://github.com/restic/restic/pull/3300
if ! truthy "${DRY_RUN:-}"
then
    info "Restoring latest snapshot for host ${source_uuid}..."
    /usr/bin/restic -r "${repository}" --verbose restore latest --target "${cache}" --host "${source_uuid}"
fi

info "Syncing files from ${cache}/ to ${username}@${target_uuid}:/${DEVICE_DATA_ROOT}/..."
/usr/bin/rsync -avz -e "$(rsync_rsh "${username}" "${target_uuid}")" "${cache}/" "${target_uuid}:/${DEVICE_DATA_ROOT}/" --delete "${dry_run[@]}"

if ! truthy "${DRY_RUN:-}"
then
    info "Restarting balena engine and balena-supervisor..."
    exec_ssh_cmd "${username}" "${target_uuid}" systemctl start balena balena-supervisor
fi

info "Completed restore!"
