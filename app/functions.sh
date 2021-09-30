#!/usr/bin/env bash

set -eu

sanitize () {
    echo "${1//[^[:alnum:]_-]/}"
}

# https://github.com/Jeff-Russ/bash-boolean-helpers
truthy () {
	command -v "$*" >/dev/null 2>&1 || { 
		if   [ -z "$*" ];      then return 1;
		elif [ "$*" = false ]; then return 1;
		elif [ "$*" = 0 ];     then return 1;
		else return 0;
		fi
	}
	typeset cmnd="$*"
	typeset ret_code
	eval $cmnd >/dev/null 2>&1
	ret_code=$?
	return $ret_code
}

backend_config () {
    echo "/config/$(sanitize "${1}").yml"
}

init_backend() {

    local backend
    local config

    backend="${1}"
    config="$(backend_config "${backend}")"

    [ -f "${config}" ] || echo "---" > "${config}"

    echo "Generating backend config for ${backend}..."

    yq e "
        .backends.${backend}.type = strenv(BACKEND_TYPE) |
        .backends.${backend}.path = strenv(BACKEND_PATH)
        " -i "${config}"
}

init_location() {

    local backup_id
    local uuid
    local backend
    local config
    local cache

    backup_id="$(sanitize "${1}")"
    uuid="$(sanitize "${2}")"
    backend="${3}"
    cache="${4}"

    config="$(backend_config "${backend}")"

    mkdir -p "${cache}"

    local before="/usr/src/app/sync-cache.sh ${uuid} ${cache}"
    local after="date"
    local success="date"
    local failure="date"

    echo "Generating location config for ${backup_id}..."

    before="${before}" \
    after="${after}" \
    success="${success}" \
    failure="${failure}" \
    backend="${backend}" \
    cache="${cache}" \
    yq e "
        .locations.${backup_id}.from = strenv(cache) |
        .locations.${backup_id}.to = strenv(backend) |
        .locations.${backup_id}.hooks.before = [strenv(before)] |
        .locations.${backup_id}.hooks.after = [strenv(after)] |
        .locations.${backup_id}.hooks.success = [strenv(success)] |
        .locations.${backup_id}.hooks.failure = [strenv(failure)]
        " -i "${config}"
}