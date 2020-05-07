#!/bin/bash

set -eu

# make sure we are logged in via balena cli
balena whoami

# change this value as needed or pass it as an arguement when calling the script
BACKUP_DEST="${1:-${HOME}/balenaCloud}"

# change these values as needed or export them in the environment beforehand
BALENA_DEVICES="${BALENA_DEVICES:-$(balena devices | awk '{print $2}' | grep -v UUID)}"

# change these values as needed or export them in the environment beforehand
MYSQL_SERVICES="${MYSQL_SERVICES:-mysql mariadb db}"
MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-}"
MYSQL_DUMP_FILE="${MYSQL_DUMP_FILE:-/var/lib/mysql/dump.sql}"

# seconds until rsync container is automatically removed (5 min)
# increase this value if it takes longer to backup one of your devices
RSYNC_CONTAINER_WAIT=300

# you normally shouldn't need to change these
RSYNC_CONTAINER_NAME=rsync_backup
RSYNC_LOCAL_PORT=4321

# definitely don't change this function
RSYNC_RSH=$(mktemp)
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
ssh \${new_args[@]}
EOF

chmod a+x "${RSYNC_RSH}"
export RSYNC_RSH

### END DEFINITIONS - START TASKS ###

for device in ${BALENA_DEVICES}
do
    balena device "${device}"
    cat << EOF | balena ssh "${device}" --tty
uptime

set -eu

for name in ${MYSQL_SERVICES}
do
    for db in \$(balena container ls -q -f label=io.balena.service-name=\${name})
    do
        echo "running mysqldump for service \${name}..."
        balena exec \${db} sh -c 'mysqldump -v -A -uroot -p${MYSQL_ROOT_PASSWORD} > ${MYSQL_DUMP_FILE}'
    done
done

balena stop ${RSYNC_CONTAINER_NAME} &>/dev/null || true
balena rm ${RSYNC_CONTAINER_NAME} &>/dev/null || true

args="--rm -d --name ${RSYNC_CONTAINER_NAME}"
for vol in \$(balena volume ls -q -f dangling=false)
do
    echo "adding volume \${vol} to backup..."
    args="\${args} -v \${vol}:/sources/\${vol}:ro"
done

echo "starting ${RSYNC_CONTAINER_NAME} container with ${RSYNC_CONTAINER_WAIT}s timeout..."
balena run \${args} alpine sh -c 'apk add --no-cache rsync && sleep ${RSYNC_CONTAINER_WAIT}'
exit
EOF

    kill "$(pidof balena)" 2>/dev/null || true
    (balena tunnel "${device}" -p 22222:${RSYNC_LOCAL_PORT} &
    sleep 5)

    mkdir -p "${BACKUP_DEST}/${device}" 2>/dev/null || true
    echo "starting rsync backup to ${BACKUP_DEST}/${device}..."
    rsync -avz ${RSYNC_CONTAINER_NAME}:/sources/ "${BACKUP_DEST}"/"${device}"/ --delete
    kill "$(pidof balena)"
done
