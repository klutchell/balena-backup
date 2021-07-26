#!/bin/bash

set -eu

# shellcheck disable=SC1091
source /usr/src/app/ssh-agent.sh

# shellcheck disable=SC1091
source /usr/src/app/balena-api.sh

uuid="${1}"
backup_id="${2}"
username="$(get_username)"

RSYNC_RSH=$(mktemp)
cat > "${RSYNC_RSH}" <<- EOF
#!/bin/bash
new_args=()
for arg in "\$@"
do
    if [ "\${arg}" = "${uuid}" ]
    then
        new_args+=("${username}@ssh.balena-devices.com host -s ${uuid}")
    else
        new_args+=("\${arg}")
    fi
done
ssh -o LogLevel=ERROR -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \${new_args[@]}
EOF
chmod a+x "${RSYNC_RSH}"
export RSYNC_RSH

remote_ssh_cmd() {
    ssh -o LogLevel=ERROR -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 22 \
        "${username}@ssh.balena-devices.com" host -s "${uuid}" "$@"
}

echo "Stopping balena engine..."
remote_ssh_cmd systemctl stop balena.service

echo "Restoring to ${uuid} as ${backup_id}..."
backup_id="${backup_id//[^[:alnum:]_-]/}"
mkdir -p "${WORKDIR}/${backup_id}"
rsync -avz "${WORKDIR}/${backup_id}/" "${uuid}:/${DATA_ROOT}/" || true

echo "Restarting balena engine..."
remote_ssh_cmd systemctl start balena.service
