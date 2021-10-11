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

# if restic repo is unset use either /backups or /media/{uuid}/backups
if [ -z "${RESTIC_REPOSITORY:-}" ]
then
    RESTIC_REPOSITORY="${usb_storage:-}/backups"
fi

cat >/usr/src/app/storage.sh <<EOL
export CACHE_ROOT="${CACHE_ROOT}"
export RESTIC_REPOSITORY="${RESTIC_REPOSITORY}"
export RESTIC_CACHE_DIR="${CACHE_ROOT}/restic"
EOL

# shellcheck disable=SC1091
source /usr/src/app/storage.sh

release_lock

/usr/bin/restic snapshots 1>/dev/null 2>&1 || /usr/bin/restic init

/usr/bin/restic unlock || true

DRY_RUN=1 /usr/src/app/auto.sh || sleep infinity

if truthy "${BACKUP_CRON:-}"
then
    info "Starting cron..."
    echo "${BACKUP_CRON} /usr/src/app/auto.sh" > /var/spool/cron/crontabs/root
    crond -f -L /dev/stdout
else
    info "Sleeping forever..."
    sleep infinity
fi
