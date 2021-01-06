#!/bin/sh

[ -d "${HOME}/.ssh" ] || mkdir -p "${HOME}/.ssh"

[ -n "${PRIVATE_KEY}" ] && echo "${PRIVATE_KEY}" > "${HOME}/.ssh/id_rsa"

cat > "${HOME}/.ssh/config" << EOF
Host *
    StrictHostKeyChecking no
    UserKnownHostsFile=/dev/null

EOF

chmod -R 0700 "${HOME}/.ssh"

if [ -f "${HOME}/.ssh/id_rsa" ]
then
    eval "$(ssh-agent -s)" && ssh-add "${HOME}/.ssh/id_rsa"
fi

# attempt to determine if an executable
# was provided in the command or just args
if [ "${1}" = "duplicity" ] || [ -x "${1}" ] || "${1}" -v >/dev/null 2>&1
then
    exec "$@"
else
    exec duplicity "$@"
fi
