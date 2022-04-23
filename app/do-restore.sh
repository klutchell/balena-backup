#!/usr/bin/env bash

set -eu

usage() {
    cat << EOF
${0} <target_uuid> [tags] [snapshot] [repository] [path]

target_uuid : the target device to apply restored files

       tags : tags to consider when restoring snapshots

   snapshot : the snapshot to restore, default is 'latest' if not provided

 repository : the repository to use, default is $RESTIC_REPOSITORY

       path : the device target directory for restored files

EOF
    exit 2
}

print_env() {
    debug "================================================"
    debug "     script = ${0}"
    debug "   username = ${username:-}"
    debug "     target = ${target:-}"
    debug "       tags = ${tags:-}"
    debug "   snapshot = ${snapshot:-}"
    debug " repository = ${repository:-}"
    debug "       path = ${path:-}"
    debug "    dry-run = ${DRY_RUN:-}"
    debug "================================================"
}

on_exit() {
    status=$?
    unmount_cache "${path}"
    release_lock
    print_env
    debug "Exited with status ${status}"
    exit ${status}
}

[ -n "${1:-}" ] || usage

target="${1}"
shift || true
tags="${1}"
shift || true
snapshot="${1:-latest}"
shift || true
repository="${1:-$RESTIC_REPOSITORY}"
shift || true
path="${1:-$DEVICE_DATA_ROOT}"
shift || true

# shellcheck disable=SC1091
source /usr/src/app/helpers.sh

# shellcheck disable=SC1091
source /usr/src/app/balena-api.sh

username="$(get_username)"

cache="${CACHE_ROOT}/${target}@${snapshot}/${path}"

dry_run=()
truthy "${DRY_RUN:-}" && dry_run=(--dry-run)

print_env

request_lock
trap on_exit EXIT

mount_cache "${cache}" "${path}"

# shellcheck disable=SC1091
source /usr/src/app/ssh-agent.sh

/usr/bin/restic -r "${repository}" -v -v restore "${snapshot}" --target / --tag "${tags}" | cat

if ! truthy "${DRY_RUN:-}"
then
    exec_ssh_cmd "${username}" "${target}" systemctl stop balena balena-supervisor
fi

/usr/bin/rsync -avz -e "$(rsync_rsh "${username}" "${target}")" "${path}/" "${target}:/${path}/" "${dry_run[@]}" --delete

if ! truthy "${DRY_RUN:-}"
then
    exec_ssh_cmd "${username}" "${target}" systemctl restart balena balena-supervisor
fi
