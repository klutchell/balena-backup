#!/usr/bin/env bash

set -eu

usage() {
    cat << EOF
${0} <uuid> [tags] [repository] [path]

       uuid : the UUID to snapshot, aka the host

       tags : tags to help identify the snapshot, set with backup_tags device label

 repository : the repository to use, default is $RESTIC_REPOSITORY

       path : the device source directory for backed up files

EOF
    exit 2
}

print_env() {
    debug "================================================"
    debug "     script = ${0}"
    debug "   username = ${username:-}"
    debug "       host = ${host:-}"
    debug "       tags = ${tags:-}"
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

host="${1}"
shift || true
tags="${1:-}"
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

cache="${CACHE_ROOT}/${host}/${path}"

dry_run=()
truthy "${DRY_RUN:-}" && dry_run=(--dry-run)

print_env

request_lock
trap on_exit EXIT

mount_cache "${cache}" "${path}"

# shellcheck disable=SC1091
source /usr/src/app/ssh-agent.sh

/usr/bin/restic -r "${repository}" snapshots 1>/dev/null 2>&1 || /usr/bin/restic -r "${repository}" init

/usr/bin/rsync -avz -e "$(rsync_rsh "${username}" "${host}")" "${host}:/${path}/" "${path}" --delete "${dry_run[@]}"
 
/usr/bin/restic -v -r "${repository}" backup "${path}" --host "${host}" --tag "${tags}" "${dry_run[@]}" | cat
