#!/usr/bin/env bash

set -eu

# shellcheck disable=SC1091
source /usr/src/app/functions.sh

# automount storage disks at /media/{UUID}
for uuid in $(blkid -sUUID -ovalue /dev/sd??)
do
    mkdir -pv /media/"${uuid}"
    mount -v UUID="${uuid}" /media/"${uuid}"
    # mount all valid partitions but only use the last one for storage
    # this is not persistent and ordering may change on reboots
    usb_storage="/media/${uuid}"
done

# if cache root is unset use either /cache or /media/{uuid}/cache
if [ -z "${CACHE_ROOT:-}" ]
then
    CACHE_ROOT="${usb_storage:-}/cache"
fi

# if backend path is unset use either /backups or /media/{uuid}/backups
if [ "${BACKEND_TYPE}" = "local" ] && [ -z "${BACKEND_PATH:-}" ]
then
    BACKEND_PATH="${usb_storage:-}/backups"
    mkdir -p "${BACKEND_PATH}"
fi

mkdir -p "/config"
mkdir -p "${CACHE_ROOT}"
[ "${BACKEND_TYPE}" = "local" ] && mkdir -p "${BACKEND_PATH}"

rm "/config/.autorestic.lock.yml" 2>/dev/null || true

cat >/usr/src/app/.env <<EOL
BACKEND_PATH=${BACKEND_PATH}
CACHE_ROOT=${CACHE_ROOT}
EOL

echo "Starting dry-run to generate config..."
DRY_RUN=1 /usr/src/app/auto.sh

if truthy "${BACKUP_CRON}"
then
    echo "Starting cron..."
    echo "${BACKUP_CRON} /usr/src/app/auto.sh" > /var/spool/cron/crontabs/root
    crond -f -L /dev/stdout
else
    echo "Sleeping forever..."
    sleep infinity
fi
