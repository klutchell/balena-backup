#!/usr/bin/env bash

set -eu

sanitize () {
    echo "${1//[^[:alnum:]_-]/_}"
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

# returns a unique backend id for the provided type/path combinations
# 1. searches all config yml files existing backends matching this type/path
# 2. failing that, finds the first unused id in the format {type}-#
get_backend_id() {

    local backend_type
    local backend_path

    backend_type="${1}"
    backend_path="${2}"

    local backend_id

    local _type
    local _path

    for backend_id in $(yq ea -N '.backends | keys' /config/*.yml 2>/dev/null | awk '{print $NF}')
    do
        _type="$(get_backend_value "${backend_id}" "type")"
        _path="$(get_backend_value "${backend_id}" "path")"

        # this backend id exists but does not match our type/path, skip
        [ "${backend_type}" = "${_type}" ] || continue
        [ "${backend_path}" = "${_path}" ] || continue

        # this backend id exists and matches our type/path, break
        echo "${backend_id}"
        return
    done

    for i in {1..99}
    do
        backend_id="${backend_type}-${i}"

        _type="$(get_backend_value "${backend_id}" "type")"
        _path="$(get_backend_value "${backend_id}" "path")"
   
        # this backend id was not found by the above loop so it's not for us
        [ -n "${_type}" ] && [ -n "${_path}" ] && continue

        # this backend id appears unused, break
        echo "${backend_id}"
        return
    done
}

get_backend_value() {

    local backend_id
    local value
    local ret

    backend_id="${1}"
    value="${2}"

    # yq ea -N ".backends.${backend_id}.${value}" /config/*.yml 2>/dev/null || true
    for ret in $(yq ea -N ".backends.${backend_id}.${value}" /config/*.yml 2>/dev/null)
    do
        if [ "${ret}" != null ]
        then
            echo "${ret}"
            return
        fi
    done

    echo ""
}

get_backend_config() {

    local backend_id

    backend_id="${1}"

    local config="/config/${backend_id}.yml"

    [ -f "${config}" ] || echo "---" > "${config}"

    echo "${config}"
}

set_backend_config() {

    local backend_id
    local backend_type
    local backend_path

    backend_id="${1}"
    backend_type="${2}"
    backend_path="${3}"

    local config

    config="$(get_backend_config "${backend_id}")"

    local backend_key

    backend_key="$(get_backend_value "${backend_id}" "key")"

    echo "Configuring backend '${backend_id}'..."

    if [ -n "${backend_key}" ]
    then
        yq e "
        .backends.${backend_id}.type = \"${backend_type}\" |
        .backends.${backend_id}.path = \"${backend_path}\" |
        .backends.${backend_id}.key = \"${backend_key}\"
        " -i "${config}"
    else
        yq e "
        .backends.${backend_id}.type = \"${backend_type}\" |
        .backends.${backend_id}.path = \"${backend_path}\"
        " -i "${config}"
    fi
}

set_location_config() {

    local backend_id
    local uuid
    local cache
    local backup_id

    backup_id="$(sanitize "${1}")"
    uuid="$(sanitize "${2}")"
    cache="${3}"
    backend_id="${4}"

    local config
    
    config="$(get_backend_config "${backend_id}")"

    local before="/usr/src/app/sync-cache.sh ${uuid} ${cache}"
    local after="date"
    local success="echo 'success for ${backup_id}'"
    local failure="echo 'failure for ${backup_id}'"

    echo "Configuring location '${backup_id}'..."

    yq e "
    .locations.${backup_id}.from = \"${cache}\" |
    .locations.${backup_id}.to = \"${backend_id}\" |
    .locations.${backup_id}.hooks.before = [\"${before}\"] |
    .locations.${backup_id}.hooks.after = [\"${after}\"] |
    .locations.${backup_id}.hooks.success = [\"${success}\"] |
    .locations.${backup_id}.hooks.failure = [\"${failure}\"]
    " -i "${config}"
}
