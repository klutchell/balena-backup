#!/usr/bin/env bash

uuid="${1}"
username="${2}"

RSYNC_RSH="/var/lib/${uuid}.sh"
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
