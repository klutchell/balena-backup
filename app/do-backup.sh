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

on_exit() {
    status=$?
    unmount_cache "${path}"
    release_lock
    print_env
    if [ ${status} -eq 0 ]
    then
        info "Exited with status ${status}"
    else
        error "Exited with status ${status}"
    fi
}

request_lock
trap on_exit EXIT

print_env() {
    debug "================================================"
    debug " username   = ${username}"
    debug " host       = ${host}"
    debug " tags       = ${tags}"
    debug " repository = ${repository}"
    debug " path       = ${path}"
    debug " dry-run    = ${DRY_RUN:-}"
    debug "================================================"
}

# shellcheck disable=SC1091
source /usr/src/app/ssh-agent.sh

# shellcheck disable=SC1091
source /usr/src/app/balena-api.sh

print_env

dry_run=()
truthy "${DRY_RUN:-}" && dry_run=(--dry-run)

username="$(get_username)"

cache="${CACHE_ROOT}/${host}/${path}"

mount_cache "${cache}" "${path}"

/usr/bin/restic -r "${repository}" snapshots 1>/dev/null 2>&1 || /usr/bin/restic -r "${repository}" init

info "Syncing files from ${host}..."
/usr/bin/rsync -avz -e "$(rsync_rsh "${username}" "${host}")" "${host}:/${path}/" "${path}" --delete "${dry_run[@]}"
 
# TODO: append dry_run when feature is released
# https://github.com/restic/restic/pull/3300
if ! truthy "${DRY_RUN:-}"
then
    info "Creating snapshot for host ${host} with tags '${tags}'..."
    /usr/bin/restic -v -r "${repository}" backup "${path}" --host "${host}" --tag "${tags}" | cat
fi
