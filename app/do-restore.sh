#!/usr/bin/env bash

set -eu

# shellcheck disable=SC1091
source /usr/src/app/storage.sh

# shellcheck disable=SC1091
source /usr/src/app/helpers.sh

target_uuid="${1}"
shift || true
source_uuid="${1:-$target_uuid}"
shift || true
repository="${1:-$RESTIC_REPOSITORY}"
shift || true

request_lock

# shellcheck disable=SC1091
source /usr/src/app/ssh-agent.sh

# shellcheck disable=SC1091
source /usr/src/app/balena-api.sh

# shellcheck disable=SC1091
source /usr/src/app/rsync-shell.sh "${target_uuid}" "$(get_username)"

cache="${CACHE_ROOT}/${target_uuid}"

mkdir -p "${cache}"
mkdir -p "${repository}"

dry_run=()
if truthy "${DRY_RUN:-}"
then
    info "Starting dry-run of ${source_uuid} to ${target_uuid}..."
    dry_run=(--dry-run)
else
    info "Starting restore of ${source_uuid} to ${target_uuid}..."
    info "Stopping balena engine and balena-supervisor..."
    remote_ssh_cmd systemctl stop balena balena-supervisor
fi

# TODO: wait until this PR is in an official release https://github.com/restic/restic/pull/3300
truthy "${DRY_RUN:-}" || restic -r "${repository}" --verbose restore latest --target "${cache}" --host "${source_uuid}" "${@}"
rsync -avz "${cache}/" "${target_uuid}:/${DEVICE_DATA_ROOT}/" --delete "${dry_run[@]}"

if truthy "${DRY_RUN:-}"
then
    info "Completed dry-run of ${source_uuid} to ${target_uuid}..."
else
    info "Completed restore of ${source_uuid} to ${target_uuid}..."
    info "Restarting balena engine and balena-supervisor..."
    remote_ssh_cmd systemctl start balena balena-supervisor
fi

release_lock
