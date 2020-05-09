#!/bin/bash

set -eu

# cleanup temp file on exit
cleanup()
{
    local rc=$?
    kill "${tunnelpid:-}" 2>/dev/null || true
    rm -vf "${RSYNC_RSH:-}" 2>/dev/null || true
    exit $rc
}

# if an .env file exists in the same directory as this script we should source it
# and export the values so they can take precedence over the following settings
set -a
# shellcheck source=/dev/null
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.env" 2>/dev/null || true
set +a

# trap any exit code beyond this point
trap cleanup INT TERM EXIT

# attempt to login if balena token was provided and whoami returns false
if ! balena whoami &>/dev/null && [ -n "${BALENA_TOKEN:-}" ]
then
    echo "> balena login --token ********"
    balena login --token "${BALENA_TOKEN}"
fi

# attempt to login if balena credentials was provided and whoami returns false
# this is helpful if running as root and the default user token may not be accessible
if ! balena whoami &>/dev/null && [ -n "${BALENA_EMAIL:-}" ] && [ -n "${BALENA_PASSWORD:-}" ]
then
    echo "> balena login --credentials --email ******** --password ********"
    balena login --credentials --email "${BALENA_EMAIL}" --password "${BALENA_PASSWORD}"
fi

# make sure we are logged in via balena cli
echo "> balena whoami"
balena whoami

# change this value as needed or pass it as an arguement when calling the script
[ -n "${BACKUP_DEST:-}" ] || BACKUP_DEST="${HOME}/balenaCloud"

# change these values as needed or export them in the environment beforehand
[ -n "${BALENA_DEVICES:-}" ] || BALENA_DEVICES="$(balena devices | awk '{print $2}' | grep -v UUID)"

# change these values as needed or export them in the environment beforehand
[ -n "${MYSQL_SERVICES:-}" ] || MYSQL_SERVICES="mysql mariadb db"
[ -n "${MYSQL_ROOT_PASSWORD:-}" ] || MYSQL_ROOT_PASSWORD=""
[ -n "${MYSQL_DUMP_FILE:-}" ] || MYSQL_DUMP_FILE="/var/lib/mysql/dump.sql"

# seconds until rsync container is automatically removed (5 min)
# increase this value if it takes longer to backup one of your devices
[ -n "${RSYNC_CONTAINER_WAIT:-}" ] || RSYNC_CONTAINER_WAIT="300"

# you normally shouldn't need to change these
[ -n "${RSYNC_CONTAINER_NAME:-}" ] || RSYNC_CONTAINER_NAME="rsync_backup"
[ -n "${RSYNC_LOCAL_PORT:-}" ] || RSYNC_LOCAL_PORT="4321"
[ -n "${SSH_OPTS:-}" ] || SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

# definitely don't change this function
readonly RSYNC_RSH=$(mktemp)
cat > "${RSYNC_RSH}" <<- EOF
#!/bin/bash
new_args=()
for arg in "\$@"
do
    if [ "\${arg}" = "${RSYNC_CONTAINER_NAME}" ]
    then
        new_args+=("-p ${RSYNC_LOCAL_PORT} root@127.0.0.1" balena exec -i "${RSYNC_CONTAINER_NAME}")
    else
        new_args+=("\${arg}")
    fi
done
ssh ${SSH_OPTS} \${new_args[@]}
EOF

chmod a+x "${RSYNC_RSH}"
export RSYNC_RSH

### END DEFINITIONS - START TASKS ###

for device in ${BALENA_DEVICES}
do
    echo "> balena device ${device}"
    balena device "${device}"
    echo "> balena ssh ${device} --tty"
    cat << EOF | balena ssh "${device}" --tty
uptime

set -eu

for name in ${MYSQL_SERVICES}
do
    for db in \$(balena container ls -q -f label=io.balena.service-name=\${name})
    do
        echo "> balena exec \${db} sh -c 'mysqldump -v -A -uroot -p${MYSQL_ROOT_PASSWORD} > ${MYSQL_DUMP_FILE}'"
        balena exec \${db} sh -c 'mysqldump -v -A -uroot -p${MYSQL_ROOT_PASSWORD} > ${MYSQL_DUMP_FILE}'
    done
done

balena stop ${RSYNC_CONTAINER_NAME} &>/dev/null || true
balena rm ${RSYNC_CONTAINER_NAME} &>/dev/null || true

args="--rm -d --name ${RSYNC_CONTAINER_NAME}"
for vol in \$(balena volume ls -q -f dangling=false)
do
    args="\${args} -v \${vol}:/sources/\${vol}:ro"
done

echo "> balena run \${args} alpine sh -c 'apk add --no-cache rsync && sleep ${RSYNC_CONTAINER_WAIT}'"
balena run \${args} alpine sh -c 'apk add --no-cache rsync && sleep ${RSYNC_CONTAINER_WAIT}'
exit
EOF

    echo "> balena tunnel ${device} -p 22222:${RSYNC_LOCAL_PORT}"
    balena tunnel "${device}" -p 22222:${RSYNC_LOCAL_PORT} &
    tunnelpid="$!"
    sleep 5

    mkdir -p "${BACKUP_DEST}/${device}" 2>/dev/null || true

    echo "> rsync -avz ${RSYNC_CONTAINER_NAME}:/sources/ "${BACKUP_DEST}"/"${device}"/ --delete"
    rsync -avz ${RSYNC_CONTAINER_NAME}:/sources/ "${BACKUP_DEST}"/"${device}"/ --delete
    kill "${tunnelpid}"
done
