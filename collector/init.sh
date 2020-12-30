#!/bin/bash

set -e

[ -d "/keys" ] || mkdir -p "/keys"

[ -n "${BALENA_DEVICE_NAME_AT_INIT}" ] || BALENA_DEVICE_NAME_AT_INIT="$(hostname)"

PRIVATE_KEY_FILE="/keys/id_rsa"
PUBLIC_KEY_FILE="/keys/id_rsa.pub"
KEY_COMMENT="orchestrator@${BALENA_DEVICE_NAME_AT_INIT}"

# generate host keys if not present
ssh-keygen -A

if [ ! -f "${PRIVATE_KEY_FILE}" ]
then
    # generate private/public rsa key pair
    ssh-keygen -b 2048 -t rsa -f "${PRIVATE_KEY_FILE}" -q -N "" -C "${KEY_COMMENT}"
fi

# add public rsa key to authorized_keys
cat "${PUBLIC_KEY_FILE}" > /keys/authorized_keys

chmod -R 0700 "/keys"

_term() { 
    kill -TERM "${CRON_PID}" 2>/dev/null
}

trap _term SIGINT SIGTERM

# do not detach (-D), log to stderr (-e), passthrough other arguments
exec /usr/sbin/sshd -D -e "$@" &

# then attach to it so we can trap SIGINT and SIGKILL messages
SSHD_PID="$!"
wait "${SSHD_PID}"
