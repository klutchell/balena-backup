# balenaBackup

A non-interactive backup utility for balenaCloud managed devices.

## Getting Started

You can one-click-deploy this project to balena using the button below:

[![deploy with balena](https://www.balena.io/deploy.svg)](https://dashboard.balena-cloud.com/deploy?repoUrl=https://github.com/balena-io-playground/balena-backup)

## Manual Deployment

Alternatively, deployment can be carried out by manually creating a [balenaCloud account](https://dashboard.balena-cloud.com) and application,
flashing a device, downloading the project and pushing it via the [balena CLI](https://github.com/balena-io/balena-cli).

### Environment Variables

| Name                | Description                                                                                                                                          |
| ------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| `API_KEY`           | (required) Session token or API key to authenticate with the balenaCloud API (<https://www.balena.io/docs/learn/manage/account/#access-tokens>).     |
| `API_URL`           | URL for balenaCloud API. Defaults to `https://api.balena-cloud.com` if not provided.                                                                 |
| `TZ`                | The timezone in your location. Find a [list of all timezone values here](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).              |
| `DEVICE_DATA_ROOT`  | Root directory on the remote devices to cache and backup. Default is `/mnt/data/docker/volumes` to backup named volumes only.                        |
| `RESTIC_REPOSITORY` | Restic repository path for encrypted snapshots. Defaults to local volume, or USB storage if detected.                                                |
| `RESTIC_PASSWORD`   | Restic repository password for encrypted snapshots. Only change this if you also change the repository path.                                         |
| `BACKUP_CRON`       | Cron schedule to poll device labels and perform backups. See [this page](https://crontab.guru/examples.html) for examples. Default is every 8 hours. |
| `SET_HOSTNAME`      | Set a custom hostname on application start. Defaults to `balena`.                                                                                    |

All restic environment variables are outlined [in their documentation](https://restic.readthedocs.io/en/v0.12.1/040_backup.html#environment-variables).

## Usage

Add a new tag key `backup_tags` in the Dashboard in order to enable backups for a specific device.

The `backup_tags` value should be a comma separated list used to help identify snapshots.

The app will find online devices with that tag and cache the data volumes on a local volume or disk.

Note that a new SSH key will be added to your dashboard as part of the authentication process.

The app will encrypt and upload snapshots of each cache directory to the cloud backend of your choosing.

Connecting a USB storage device is recommended and will automatically be used for cache and local backups.

### Backing up

Open a shell into the `app` service either via the Dashboard or
via balena CLI and call the backup script with the device UUID and optional tags.

```bash
/usr/src/app/do-backup.sh <uuid> [tags] [repository]
```

### Restoring from backup

Open a shell into the `app` service either via the Dashboard or
via balena CLI and call the restore script with the target UUID and optionally the source UUID if not the same.

```bash
/usr/src/app/do-restore.sh <target_uuid> [source_uuid] [repository]
```

The restore command will temporarily stop the balena engine on the remote device in order to restore volumes.

### Listing all snapshots

```bash
# source the storage env vars
. /usr/src/app/storage.sh

# https://restic.readthedocs.io/en/v0.12.1/045_working_with_repos.html
restic snapshots --group-by host,tags
```

### Removing backup snapshots

```bash
# source the storage env vars
. /usr/src/app/storage.sh

# https://restic.readthedocs.io/en/v0.12.1/060_forget.html
restic forget --tag foo --keep-last 1 --prune
```

## Contributing

Please open an issue or submit a pull request with any features, fixes, or changes.
