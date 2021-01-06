#!/bin/sh

# This script is not intended to be run manually.
# Instead execute.sh will substitute the env vars listed
# in SHELL_FORMAT and will pipe this file to 'balena ssh'
# so the steps are executed on the remote device.

set -e

# persist these volumes on the fleet device if possible
# if they get purged that's probably okay too
mounts="-v duplicity:/home/root/.cache/duplicity -v gnupg:/home/root/.gnupg -v backups:/backups"

if [ "${BACKUP_VOLUMES}" = "all" ]
then
    for vol in $(balena volume ls -q -f dangling=false | grep '_')
    do
        mounts="${mounts} -v ${vol}:/volumes/${vol#*_}:${MOUNT_MODE}"
    done
else
    # shellcheck disable=SC2086
    for vol in $(echo ${BACKUP_VOLUMES} | sed "s/,/ /g")
    do
        mounts="${mounts} -v ${vol}:/volumes/${vol}:${MOUNT_MODE}"
    done
fi

balena pull "${DOCKER_IMAGE}"

# shellcheck disable=SC2086
balena run --rm \
    -e "PASSPHRASE=${PASSPHRASE}" \
    -e "CLI_API_KEY=${CLI_API_KEY}" \
    -e "PRIVATE_KEY=${PRIVATE_KEY}" \
    ${mounts} "${DOCKER_IMAGE}" ${DOCKER_CMD}

exit
