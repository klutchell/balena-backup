#!/usr/bin/env bash

set -eu

usage() {
    cat << EOF
${0} <source_uuid> [snapshot] [target_uuid] [repository] [path]

source_uuid : the UUID that created the snapshot, aka the host

   snapshot : the snapshot to restore, default is 'latest' if not provided

target_uuid : the target device to apply restored files, default is the original host

 repository : the repository to use, default is $RESTIC_REPOSITORY

       path : the device target directory for restored files

EOF
    exit 2
}

print_env() {
    debug "================================================"
    debug "     script = ${0}"
    debug "   username = ${username:-}"
    debug "       host = ${host:-}"
    debug "   snapshot = ${snapshot:-}"
    debug "     target = ${target:-}"
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
snapshot="${1:-latest}"
shift || true
target="${1:-$host}"
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

cache="${CACHE_ROOT}/${host}@${snapshot}/${path}"

dry_run=()
truthy "${DRY_RUN:-}" && dry_run=(--dry-run)

print_env

request_lock
trap on_exit EXIT

rm -rf "${cache}" 2>/dev/null || true

mount_cache "${cache}" "${path}"

# shellcheck disable=SC1091
source /usr/src/app/ssh-agent.sh

/usr/bin/restic -r "${repository}" -v -v restore "${snapshot}" --target / --host "${host}" | cat

if ! truthy "${DRY_RUN:-}"
then
    exec_ssh_cmd "${username}" "${target}" systemctl stop balena balena-supervisor
fi

/usr/bin/rsync -avz -e "$(rsync_rsh "${username}" "${target}")" "${path}/" "${target}:/${path}/" "${dry_run[@]}"

if ! truthy "${DRY_RUN:-}"
then
    exec_ssh_cmd "${username}" "${target}" systemctl start balena balena-supervisor
fi
