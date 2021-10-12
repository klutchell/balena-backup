#!/usr/bin/env bash

set -eu

# shellcheck disable=SC1091
source /usr/src/app/helpers.sh

mkdir -pv "${CACHE_ROOT}"
mkdir -pv "/backups"

mapfile -t usb_devices < <(lsblk -J -O | jq -r '.blockdevices[] | 
    select(.subsystems=="block:scsi:usb:platform" or .subsystems=="block:scsi:usb:pci:platform") | 
    .path, .children[].path')

# automount USB device partitions at /media/{UUID}
if [ ${#usb_devices[@]} -gt 0 ]
then
    info "Found USB storage block devices: ${usb_devices[*]}"
    for uuid in $(blkid -sUUID -ovalue "${usb_devices[@]}")
    do
        mkdir -pv "/media/${uuid}"
        mount -v UUID="${uuid}" "/media/${uuid}" || continue

        # bind mount on top of existing volume
        mkdir -pv "/media/${uuid}/cache"
        mount -v -o bind "/media/${uuid}/cache" "${CACHE_ROOT}" || continue

        # bind mount on top of existing volume
        mkdir -pv "/media/${uuid}/backups"
        mount -v -o bind "/media/${uuid}/backups" "/backups" || continue

        break
    done
fi

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
