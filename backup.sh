#!/bin/bash

set -ex

# MYSQL_ROOT_PASSWORD must be set
[ -n "${MYSQL_ROOT_PASSWORD}" ] || exit 1

# 1. for each device on balenaCloud account
# 2. log in to Host via balena ssh
# 3. print uptime
# 4. for each service named 'mariadb'
# 5. dump all mysql databases to /var/lib/mysql/dump.sql
# 6. repeat step 5 for each service named 'mariadb'
# 7. stop and remove any existing containers named 'vol_backup'
# 8. create a list of all non-dangling volumes
# 9. start and alpine container and mount all volumes from step 8
# 10. install rsync in the alpine container and sleep for next steps (5 min)
# 11. logoff the Host
# 12. kill any existing balena tunnel process
# 13. start a new tunnel from localhost:1234 to remote Host :22222 (ssh)
# 14. customize rsync shell command to exec into alpine container on remote Host
# 15. run rsync to backup all sources (volumes) from the alpine container to a local directory
# 16. kill any existing balena tunnel process
# 17. the alpine container should die and clean up 5 minutes after starting
# 18. repeat steps 2-17 for each device on balenaCloud account

for device in $(balena devices | awk '{print $2}' | grep -v UUID)
do
    cat << EOF | balena ssh "${device}" --tty
set -ex
uptime

for db in \$(balena container ls -q -f label=io.balena.service-name=mariadb)
do
    balena exec \${db} sh -c 'mysqldump -v -A -uroot -p${MYSQL_ROOT_PASSWORD} > /var/lib/mysql/dump.sql'
done

balena stop vol_backup || true
balena rm vol_backup || true

args="--rm -d --name vol_backup"
for vol in \$(balena volume ls -q -f dangling=false)
do
    args="\${args} -v \${vol}:/sources/\${vol}:ro"
done

balena run \${args} alpine sh -c 'apk add --no-cache rsync && sleep 300'
exit
EOF
    kill "$(pidof balena)" || true
    (balena tunnel "${device}" -p 22222:4321 &
    sleep 5)
    export RSYNC_RSH="./rsync-shell.sh" && chmod +x "${RSYNC_RSH}"
    rsync -avz vol_backup:/sources/ ./backups/"${device}"/
    kill "$(pidof balena)"
done
