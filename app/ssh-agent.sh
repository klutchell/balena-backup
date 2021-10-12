#!/usr/bin/env bash

set -eu

if [ -z "${BALENA_DEVICE_UUID:-}" ]
then
    BALENA_DEVICE_UUID="$(curl https://uuid.rocks/plain)"
fi

# shellcheck disable=SC1091
source /usr/src/app/balena-api.sh

username="$(get_username)"
user_id="$(get_user_id)"

private_key_file="/keys/id_rsa"
public_key_file="/keys/id_rsa.pub"
public_key_name="${username}@${BALENA_DEVICE_UUID}"

if [ ! -f "${private_key_file}" ]
then
    info "Generating new SSH key pair..."
    ssh-keygen -b 2048 -t rsa -f "${private_key_file}" -q -N "" -C "${public_key_name}"
fi

if add_new_ssh_key "${user_id}" "$(<"${public_key_file}")" "${public_key_name}" 2>/dev/null
then
    info "Added new SSH key to balenaCloud..."
fi

eval "$(ssh-agent)"
ssh-add "${private_key_file}"
