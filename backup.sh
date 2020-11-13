#!/bin/bash

set -euxo pipefail

cleanup()
{
    local rc=$?
    kill "${TUNNEL_PID:-}" 2>/dev/null || true
    envsubst "${SHELL_FORMAT}" < uninstall.sh | balena ssh "${UUID}" --tty
    balena key rm "$(balena keys | grep "$(hostname)" | awk '{print $1}')" --yes || true
    exit $rc
}

# trap any exit code beyond this point
trap cleanup INT TERM EXIT

# generate temporary rsa key
ssh-keygen -b 2048 -t rsa -f ~/.ssh/id_rsa -q -N "" -C "$(hostname)"

# export public rsa key and a random string to use for the remote container name
PUBLIC_KEY="$(<~/.ssh/id_rsa.pub)"
CONTAINER_NAME="$(openssl rand -hex 20)"
export PUBLIC_KEY CONTAINER_NAME

SHELL_FORMAT='$TUNNEL_PORT $PUBLIC_KEY $CONTAINER_NAME $BACKUP_TIMEOUT'

# login to balena with provided api key
balena login --token "${BALENA_API_KEY}"

# print whoami for reference
balena whoami

# add public rsa key to balena cloud
balena key add "$(hostname)" ~/.ssh/id_rsa.pub

RSYNC_RSH="$(mktemp)"
envsubst "${SHELL_FORMAT}" < "rsync.rsh" > "${RSYNC_RSH}"
chmod a+x "${RSYNC_RSH}"
export RSYNC_RSH

_term() { 
    kill -TERM "${SSH_PID}" 2>/dev/null
}

trap _term SIGINT SIGTERM

# generate a list of all online balena devices if a list was not provided
[ -n "${BALENA_DEVICES+x}" ] || BALENA_DEVICES="$(balena devices -j | jq '.[] | select(.is_online==true) | .id')"

for device in ${BALENA_DEVICES}
do
    # convert the short uuid to the long uuid required for balena ssh
    UUID="$(balena device "${device}" | grep UUID: | awk '{print $2}')"

    # pipe the server script to balena ssh
    envsubst "${SHELL_FORMAT}" < install.sh | balena ssh "${UUID}" --tty &
    SSH_PID="$!"
    wait "${SSH_PID}"

    # start balena tunnel and store the pid
    balena tunnel "${UUID}" -p "22222:${TUNNEL_PORT}" &
    TUNNEL_PID="$!"

    # allow the tunnel a few seconds to connect
    sleep 5

    # create backup destination dir
    mkdir -p "${BACKUP_DESTDIR}/${UUID}"

    # rsync all source volumes from remote container
    rsync -avz "${CONTAINER_NAME}:/sources/" "${BACKUP_DESTDIR}/${UUID}"/ --delete

    # kill the tunnel process
    kill "${TUNNEL_PID}"

    envsubst "${SHELL_FORMAT}" < uninstall.sh | balena ssh "${UUID}" --tty &
    SSH_PID="$!"
    wait "${SSH_PID}"

done
