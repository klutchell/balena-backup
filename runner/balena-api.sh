#!/bin/bash

[ -z "${API_URL:-}" ] && [ -n "${BALENA_API_URL:-}" ] && API_URL="${BALENA_API_URL}"

# https://www.balena.io/docs/reference/api/resources/whoami/
get_username () {
    curl -fsSL -w "\n" -X GET \
        "${API_URL}/user/v1/whoami" \
        -H "Authorization: Bearer ${API_KEY}" \
        -H 'Content-Type: application/json' | \
        jq -r '.username'
}

# https://www.balena.io/docs/reference/api/resources/whoami/
get_user_id () {
    curl -fsSL -w "\n" -X GET \
        "${API_URL}/user/v1/whoami" \
        -H "Authorization: Bearer ${API_KEY}" \
        -H 'Content-Type: application/json' | \
        jq -r '.id'
}

# https://www.balena.io/docs/reference/api/resources/device_tag/
get_online_uuids_with_tag_key () {
    local tag_key="${1}"
    curl -fsSL -w "\n" -X GET \
        "${API_URL}/v6/device_tag?\$filter=tag_key%20eq%20%27${tag_key}%27%20and%20device/is_online%20eq%20true&\$expand=device(\$select=uuid)" \
        -H "Authorization: Bearer ${API_KEY}" \
        -H 'Content-Type: application/json' | \
        jq -r '.d[].device[].uuid'
}

# https://www.balena.io/docs/reference/api/resources/device_tag/
get_uuid_tag_value () {
    local uuid="${1}"
    local tag_key="${2}"
    curl -fsSL -w "\n" -X GET \
        "${API_URL}/v6/device_tag?\$filter=device/uuid%20eq%20%27${uuid}%27" \
        -H "Authorization: Bearer ${API_KEY}" \
        -H 'Content-Type: application/json' | \
        jq -r --arg TAG_KEY "${tag_key}" '.d[] | select(.tag_key==$TAG_KEY) | .value'
}

# https://www.balena.io/docs/reference/api/resources/user__has__public_key/
add_new_ssh_key () {
    local user="${1}"
    local public_key="${2}"
    local title="${3}"
    curl -fsSL -w "\n" -X POST \
        "${API_URL}/v6/user__has__public_key" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${API_KEY}" \
        --data "{
            \"public_key\": \"${public_key}\",
            \"title\": \"${title}\",
            \"user\": \"${user}\"
        }"
}
