# balenaBackup

A non-interactive backup utility for balenaCloud managed devices.

## How It Works

- The balena API is used to get a list of online balenaCloud devices with the `backup_id` tag.
- The `backup_id` tag value will be used as the backup name and should be unique.
- For each discovered device, the docker volumes directory will be mirrored to a local cache via SSH proxy.
- Each local cache is then encrypted and uploaded in chunks to your preferred cloud backend.
- Backups and restores can be performed manually from the app container console.
- Connecting a USB storage device is recommended and will automatically be used for cache and local backups.

## Getting Started

You can one-click-deploy this project to balena using the button below:

[![deploy with balena](https://www.balena.io/deploy.svg)](https://dashboard.balena-cloud.com/deploy?repoUrl=https://github.com/balena-io-playground/balena-backup)

## Manual Deployment

Alternatively, deployment can be carried out by manually creating a [balenaCloud account](https://dashboard.balena-cloud.com) and application,
flashing a device, downloading the project and pushing it via the [balena CLI](https://github.com/balena-io/balena-cli).

### Environment Variables

| Name                | Description                                                                                                                                      |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| `API_KEY`           | (required) Session token or API key to authenticate with the balenaCloud API (<https://www.balena.io/docs/learn/manage/account/#access-tokens>). |
| `API_URL`           | URL for balenaCloud API. Defaults to `https://api.balena-cloud.com` if not provided.                                                             |
| `TZ`                | The timezone in your location. Find a [list of all timezone values here](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).          |
| `DEVICE_DATA_ROOT`  | Root directory on the remote devices to cache and backup. Default is `/mnt/data/docker/volumes` to backup named volumes only.                    |
| `RESTIC_REPOSITORY` | Restic repository path. Defaults to local. See <https://restic.readthedocs.io/en/v0.12.1/030_preparing_a_new_repo.html>.                         |
| `RESTIC_PASSWORD`   | Restic repository password. See <https://restic.readthedocs.io/en/v0.12.1/030_preparing_a_new_repo.html>.                                        |
| `BACKUP_CRON`       | Cron schedule to poll device labels and perform backups. See [this page](https://crontab.guru/examples.html) for examples.                       |

Additional restic environment variables are outlined here: <https://restic.readthedocs.io/en/v0.12.1/040_backup.html#environment-variables>

## Usage

Add a new tag key `backup_id` in the Dashboard in order to enable backups for a specific device.

The tag value will be used as the backup name and should be unique.

The app will find online devices with that tag and cache the data volumes to a local directory or disk.

Note that a new SSH key will be added to your dashboard as part of the authentication process.

The app will encrypt and upload snapshots of each cache directory to the cloud backend of your choosing.

### Manual Backup

Open a shell into the `app` service either via the Dashboard or
via balena CLI and call the backup script with the device UUID and backup_id.

```bash
DRY_RUN=1 /usr/src/app/do-backup.sh <backup_id> <uuid> [repository]
```

### Manual Restore

Open a shell into the `app` service either via the Dashboard or
via balena CLI and call the restore script with the device UUID and backup_id.

```bash
DRY_RUN=1 /usr/src/app/do-restore.sh <backup_id> <uuid> [repository]
```

The restore command will temporarily stop the balena engine on the remote device in order to restore volumes.

## Contributing

Please open an issue or submit a pull request with any features, fixes, or changes.
