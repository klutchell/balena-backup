#!/usr/bin/env bash

set -eu

# shellcheck disable=SC1091
source /usr/src/app/helpers.sh

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
if [ -z "${RESTIC_REPOSITORY:-}" ]
then
    RESTIC_REPOSITORY="${usb_storage:-}/backups"
fi

cat >/usr/src/app/.env <<EOL
CACHE_ROOT=${CACHE_ROOT}
RESTIC_REPOSITORY=${RESTIC_REPOSITORY}
RESTIC_CACHE_DIR=${CACHE_ROOT}/restic
EOL

rm /var/run/app.lock 2>/dev/null || true

DRY_RUN=1 /usr/src/app/auto.sh || sleep infinity

if truthy "${BACKUP_CRON:-}"
then
    echo "Starting cron..."
    echo "${BACKUP_CRON} /usr/src/app/auto.sh" > /var/spool/cron/crontabs/root
    crond -f -L /dev/stdout
else
    echo "Sleeping forever..."
    sleep infinity
fi
