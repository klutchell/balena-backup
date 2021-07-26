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

echo "Backing up ${uuid} as ${backup_id}..."
backup_id="${backup_id//[^[:alnum:]_-]/}"
mkdir -p "${WORKDIR}/${backup_id}"
rsync -avz "${uuid}:/${DATA_ROOT}/" "${WORKDIR}/${backup_id}/" --delete || true
