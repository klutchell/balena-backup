#!/bin/bash

set -eu

[ -n "${BALENA_API_URL:-}" ] || BALENA_API_URL="https://api.balena-cloud.com"

get_online_devices_by_tag () {
    local tag_key="${1}"
    local value="${2}"
    local filter="tag_key%20eq%20%27${tag_key}%27%20and%20value%20eq%20%27${value}%27%20and%20device/is_online%20eq%20true"
    curl -fsSL -X GET "${BALENA_API_URL}/v5/device_tag?\$filter=${filter}&\$expand=device(\$select=uuid)" \
        -H "Authorization: Bearer ${CLI_API_KEY}" -H 'Content-Type: application/json' | \
        jq -r .d[].device[].uuid
}

get_device_tag_value () {
    local uuid="${1}"
    local tag_key="${2}"
    curl -fsSL -X GET "${BALENA_API_URL}/v5/device_tag?\$filter=device/uuid%20eq%20%27${uuid}%27" \
        -H "Authorization: Bearer ${CLI_API_KEY}" -H 'Content-Type: application/json' | \
        jq -r --arg TAG_KEY "${tag_key}" '.d[] | select(.tag_key==$TAG_KEY) | .value'
}
