#!/bin/bash
CONTAINER_NAME='vol_backup'
TUNNEL_OPTS='-p 4321 root@127.0.0.1'
new_args=()
for arg in "$@"; do
  if [ "$arg" = "${CONTAINER_NAME}" ]; then
    new_args+=("${TUNNEL_OPTS}" balena exec -i "${CONTAINER_NAME}")
  else
    new_args+=("${arg}")
  fi
done
echo original command: ssh "$@" >&2
echo modified command: ssh "${new_args[@]}" >&2
ssh ${new_args[@]}