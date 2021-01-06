#!/bin/bash

# helper script to take a UUID and CMD
# and execute CMD in a specified docker
# image on the remote device

set -euo pipefail

UUID="${1}"
DOCKER_CMD="${2}"

test -n "${UUID}"
test -n "${DOCKER_CMD}"

export DOCKER_CMD

test -n "${CLI_API_KEY}"
test -n "${DOCKER_IMAGE}"
test -n "${BACKUP_VOLUMES}"
test -n "${MOUNT_MODE}"

# use a temporary balena environment to avoid conflicts
BALENARC_DATA_DIRECTORY="$(mktemp -d)"
export BALENARC_DATA_DIRECTORY

# login to balena with provided api key
balena login --token "${CLI_API_KEY}"

# pipe the container run script to balena ssh
# shellcheck disable=SC2016
SHELL_FORMAT='$DOCKER_IMAGE $DOCKER_CMD $PASSPHRASE $PRIVATE_KEY $BACKUP_VOLUMES $MOUNT_MODE'
envsubst "${SHELL_FORMAT}" < /usr/src/app/pipeme.sh | balena ssh "${UUID}"
