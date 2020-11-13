#!/bin/bash
new_args=()
for arg in "$@"
do
    if [ "${arg}" = "${CONTAINER_NAME}" ]
    then
        new_args+=("-p ${TUNNEL_PORT} root@127.0.0.1" balena exec -i "${CONTAINER_NAME}")
    else
        new_args+=("${arg}")
    fi
done
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${new_args[@]}
