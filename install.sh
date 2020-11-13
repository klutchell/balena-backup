#!/bin/sh

cp /home/root/.ssh/authorized_keys /home/root/.ssh/authorized_keys.orig
echo "${PUBLIC_KEY}" >> /home/root/.ssh/authorized_keys

volumes=
for vol in $(balena volume ls -q -f dangling=false)
do
    volumes="${volumes} -v ${vol}:/sources/${vol}:ro"
done

balena run --rm -d ${volumes} --name "${CONTAINER_NAME}" alpine sh -c "apk add --no-cache rsync && sleep ${BACKUP_TIMEOUT}"

exit
