# balenaBackup

A non-interactive backup utility for balenaCloud managed devices.

## How It Works

- The runner will use the balena API to get a list of online devices with the `backup_id` tag.
- The `backup_id` tag value will be used as the backup name and should be unique.
- For each discovered device, the docker volumes directory will be mirrored with rsync to a local volume.
- The rsync is tunneled over SSH via the balena proxy so devices do not need to be on the same network.
- The fleet devices being backed up should not be impacted by this process at all.
- The automatic backups can be disabled by setting `INTERVAl` to `off`.
- Backups and restores can also be performed manually on-demand.
- Restores will stop the balena engine and restart it after syncing volumes.
- Encrypted offsite snapshots of the backups can be added with the [duplicati block](https://github.com/klutchell/balenablocks-duplicati).

## Getting Started

You can one-click-deploy this project to balena using the button below:

[![deploy with balena](https://www.balena.io/deploy.svg)](https://dashboard.balena-cloud.com/deploy?repoUrl=https://github.com/balena-io-playground/balena-backup)

## Manual Deployment

Alternatively, deployment can be carried out by manually creating a [balenaCloud account](https://dashboard.balena-cloud.com) and application,
flashing a device, downloading the project and pushing it via the [balena CLI](https://github.com/balena-io/balena-cli).

### Environment Variables

| Name       | Description                                                                                                                           |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| `API_URL`  | URL for balenaCloud API. Defaults to `https://api.balena-cloud.com` if not provided.                                                  |
| `API_KEY`  | Session token or API key to authenticate with the balenaCloud API (<https://www.balena.io/docs/learn/manage/account/#access-tokens>). |
| `INTERVAL` | Delay between each run of the rsync backups. Suffix 's' for seconds, 'm' for minutes, 'h' for hours or 'd' for days. Default is `4h`. |

## Usage

Add a new tag key `backup_id` in the Dashboard in order to enable backups for a specific device.

The tag value will be used as the backup name and should be unique.

The runner will find online devices with that tag and rsync the data volumes to a local volume.

Note that a new SSH key will be added to your dashboard as part of the authentication process.

### Manual Backup

Open a shell into the `runner` service either via the Dashboard or
via balena CLI and call the backup script with the device UUID and backup_id.

```bash
/usr/src/app/backup.sh <uuid> <backup_id>
```

### Manual Restore

Open a shell into the `runner` service either via the Dashboard or
via balena CLI and call the restore script with the device UUID and backup_id.

```bash
/usr/src/app/restore.sh <uuid> <backup_id>
```

The restore command will temporarily stop the balena engine on the remote device in order to restore volumes.

### Extras

Works well with the [duplicati block](https://github.com/klutchell/balenablocks-duplicati) to make encrypted snapshots offsite!

Add the following services and volumes to the existing docker-compose file in this project.

```yaml
services:
  duplicati:
    image: linuxserver/duplicati:latest
    environment:
      PUID: "0"
      PGID: "0"
      CLI_ARGS: --webservice-interface=any
    ports:
      - 80:8200/tcp
    volumes:
      - duplicati:/config
      - backups:/source

volumes:
  duplicati:
```

## Contributing

Please open an issue or submit a pull request with any features, fixes, or changes.
