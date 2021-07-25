#!/bin/bash

set -eu

[ -n "${BALENA_DEVICE_NAME_AT_INIT:-}" ] || BALENA_DEVICE_NAME_AT_INIT="$(hostname)"

# shellcheck disable=SC1091
source /usr/src/app/balena-api.sh

username="$(get_username)"
user_id="$(get_user_id)"

private_key_file="/keys/id_rsa"
public_key_file="/keys/id_rsa.pub"
public_key_name="${username}@${BALENA_DEVICE_NAME_AT_INIT}"

if [ ! -f "${private_key_file}" ]
then
    echo "Generating new SSH key pair..."
    ssh-keygen -b 2048 -t rsa -f "${private_key_file}" -q -N "" -C "${public_key_name}"
fi

# add public rsa key to balena cloud
echo "Adding SSH key to balenaCloud..."
add_new_ssh_key "${user_id}" "$(<"${public_key_file}")" "${public_key_name}" || true

eval "$(ssh-agent)"
ssh-add "${private_key_file}"
