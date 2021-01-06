# balena-backup

A non-interactive backup utility for balenaCloud managed devices.

Uses [duplicity](http://duplicity.nongnu.org/) to create tar-format volumes encrypted with GnuPG.

The fleet devices being backed up should not be impacted by this process at all.

## Requirements

One or more devices managed via [balenaCloud](https://www.balena.io/cloud/)

This app requires a balena API token from your Dashboard in order to administer your fleet.

## Getting Started

You can one-click-deploy this project to balena using the button below:

[![balena deploy button](https://www.balena.io/deploy.svg)](https://dashboard.balena-cloud.com/deploy?repoUrl=https://github.com/balena-io-playground/balena-backup)

## Manual Deployment

Alternatively, deployment can be carried out by manually creating a [balenaCloud account](https://dashboard.balena-cloud.com) and application,
flashing a device, downloading the project and pushing it via either Git or the [balena CLI](https://github.com/balena-io/balena-cli).

## Usage

### Authentication

This orchestrator requires a balena API key from your Dashboard in order to administer your fleet.

<https://dashboard.balena-cloud.com/preferences/access-token>

It will use this authentication for the following tasks:

- List fleet devices and their tags via balena API
- Add a public SSH key to your fleet account

Once your key has been generated, keep it somewhere safe as you'll need it for future steps.

### Environment Variables

The orchestrator uses environment variables to set some defaults in cases where device tags are not provided.

However both your fleet API key and backups passphrase are required for application start.

- `CLI_API_KEY`: API key for balena CLI (<https://dashboard.balena-cloud.com/preferences/access-tokens>).
- `PASSPHRASE`: This passphrase is passed to GnuPG to encrypt your backups. Avoid changing this.
- `BACKUP_URL`: A global default backup endpoint URL to use in cases where one is not provided via device tags.
- `BACKUP_VOLUMES`: A global default backup volumes list to use in cases where one is not provided via device tags.
- `BACKUP_SCHEDULE`: A global default backup schedule to use in cases where one is not provided via device tags.

### Device Tags

In order to enable per-device backups set the following tags(s) on the fleet device(s):

- `backupEnabled`: Set this tag to `true` to enable backups.
Devices without this tag are ignored.
- `backupUrl`: (optional) Duplicity supported backend URL and additional options if required.
If not provided the value of `BACKUP_URL` on the orchestrator will be used.
- `backupVolumes`: (optional) Comma separated list of named volumes to back up.
If not provided the value of `BACKUP_VOLUMES` on the orchestrator will be used.
- `backupSchedule`: (optional) Provide a custom crontab formatted schedule for this device.
If not provided the value of `BACKUP_SCHEDULE` on the orchestrator will be used.

### Secrets

Any environment variables set on the orchestrator will be substituted in the backup URL.
This allows for setting secrets on the orchestrator and avoid having them exposed as device tags.

For example, by setting `COLLECTOR_IP=192.168.8.201` on the orchestrator,
your device tag may now be `backupUrl=rsync://root@$COLLECTOR_IP:54321//backups/$UUID`.

Another example, by setting `B2_ID=foo` and `B2_KEY=bar` on the orchestrator,
your device tag may now be `backupUrl=b2://$SCRT_B2_ID:$SCRT_B2_KEY@bucket_name/backups/$UUID`.

### Orchestrator

The orchestrator includes a cron instance to run backups on a schedule.
It also includes scripts for running on-demand backup/restore commands.

For each online, correctly tagged device, the scheduler will perform the following tasks:

1. Connect via `balena ssh` to the remote device.
2. Pull and run a custom docker image with Duplicity pre-installed.
3. Mount some or all of the existing named volumes on the device.
4. Run the Duplicity backup command with the provided endpoint URL.
5. Stop and remove the Duplicity container.
6. Named volumes `duplicity`, `gnupg`, and `backups` may persist on the device.

### Collector

The `collector` service is an SSH backend and can optionally used as a backup endpoint.

On first run it will generate a RSA private/public key pair and make it available to the orchestrator.

The orchestrator will then add the public key to the balena fleet account
in order to execute `balena ssh` commands.

The orchestrator will also add the private key to the fleet device being
backed up in order to authenticate with the connector service as a backup endpoint if desired.

Here's how to use the collector as an rsync backup endpoint.

If a firewall/NAT is between the collector and the fleet device:

1. Forward public port `54321/tcp` to `54321/tcp` on the collector device
2. Determine the public IP of the collector (from the perspective of the fleet device)
3. Set the `backupUrl` tag on the fleet device to `rsync://root@<WAN-IP>:54321//backups/$UUID`

If the collector and the fleet device are on the same LAN:

1. Set the `backupUrl` tag on the fleet device to `rsync://root@<LAN-IP>:54321//backups/$UUID`

### Backends and their URL formats

Duplicity's supported backends are listed here:

<http://www.nongnu.org/duplicity/vers8/duplicity.1.html#sect7>

Some of the endpoints require additional modules that may not be installed by default.
Feel free to open an issue or submit a pull request with the missing modules.

### Manual Backup

Open a shell into the `orchestrator` service either via the Dashboard or
via balena CLI and call the backup script with the device UUID.

```bash
# run backup using the URL and volumes defined in device tags
backup.sh <UUID>
```

### Manual Restore

Open a shell into the `orchestrator` service either via the Dashboard or
via balena CLI and call the restore script with the device UUID.

```bash
# run restore using the URL and volumes defined in device tags
restore.sh <UUID>
```

### Custom Commands

There is a generic execute wrapper available so you may execute custom
Duplicati commands on the remote device.

Open a shell into the `orchestrator` service either via the Dashboard or
via balena CLI and call the execute script with the device UUID and the
command to execute.

Note that custom commands do not use the device tags, so it will
use the global defaults unless otherwise specified.

```bash
# example: run a manual backup to the backup volume on the fleet device
execute.sh <UUID> "-v 9 --allow-source-mismatch /volumes file:///backups"

# example: run a manual restore from the backup volume on the fleet device
# note that mount mode was changed to read/write for this operation
MOUNT_MODE="rw" execute.sh <UUID> "-v 9 --allow-source-mismatch file:///backups /volumes"

# example: run a manual backup to the collector
execute.sh <UUID> "-v 9 --allow-source-mismatch /volumes rsync://root@<COLLECTOR-IP>:54321//backups/<UUID>"

# example: run a manual restore from the collector
# note that mount mode was changed to read/write for this operation
MOUNT_MODE="rw" execute.sh <UUID> "-v 9 --allow-source-mismatch rsync://root@<COLLECTOR-IP>:54321//backups/<UUID> /volumes"

# example: compare the latest collector backup with the current files
execute.sh <UUID> "verify -v 9 rsync://root@<COLLECTOR-IP>:54321//backups/<UUID> /volumes"

# example: restore only foo/bar from an existing collector backup
# note that mount mode was changed to read/write for this operation
MOUNT_MODE="rw" execute.sh <UUID> "-v 9 foo/bar rsync://root@<COLLECTOR-IP>:54321//backups/<UUID> /volumes/foo/bar"
```

Note that all of the named volumes on the node are mounted as `/volumes/<volume name>`
so the local path must always start with `/volumes`.

Commands and usage from the `duplicity --help` menu:

```plaintext
Usage: 
  duplicity [full|incremental] [options] source_dir target_url
  duplicity [restore] [options] source_url target_dir
  duplicity verify [options] source_url target_dir
  duplicity collection-status [options] target_url
  duplicity list-current-files [options] target_url
  duplicity cleanup [options] target_url
  duplicity remove-older-than time [options] target_url
  duplicity remove-all-but-n-full count [options] target_url
  duplicity remove-all-inc-of-but-n-full count [options] target_url
  duplicity replicate source_url target_url

Backends and their URL formats:
  azure://container_name
  b2://account_id[:application_key]@bucket_name/[some_dir/]
  boto3+s3://bucket_name[/prefix]
  cf+http://container_name
  dpbx:///some_dir
  file:///some_dir
  ftp://user[:password]@other.host[:port]/some_dir
  ftps://user[:password]@other.host[:port]/some_dir
  gdocs://user[:password]@other.host/some_dir
  hsi://user[:password]@other.host[:port]/some_dir
  imap://user[:password]@other.host[:port]/some_dir
  mega://user[:password]@other.host/some_dir
  megav2://user[:password]@other.host/some_dir
  mf://user[:password]@other.host/some_dir
  onedrive://some_dir
  pca://container_name
  pydrive://user@other.host/some_dir
  rclone://remote:/some_dir
  rsync://user[:password]@other.host[:port]/relative_path
  rsync://user[:password]@other.host[:port]//absolute_path
  rsync://user[:password]@other.host[:port]::/module/some_dir
  s3+http://bucket_name[/prefix]
  s3://other.host[:port]/bucket_name[/prefix]
  scp://user[:password]@other.host[:port]/some_dir
  ssh://user[:password]@other.host[:port]/some_dir
  swift://container_name
  tahoe://alias/directory
  webdav://user[:password]@other.host/some_dir
  webdavs://user[:password]@other.host/some_dir

Commands:
  cleanup <target_url>
  collection-status <target_url>
  full <source_dir> <target_url>
  incr <source_dir> <target_url>
  list-current-files <target_url>
  restore <source_url> <target_dir>
  remove-older-than <time> <target_url>
  remove-all-but-n-full <count> <target_url>
  remove-all-inc-of-but-n-full <count> <target_url>
  verify <target_url> <source_dir>
  replicate <source_url> <target_url>
```

## Contributing

Please open an issue or submit a pull request with any features, fixes, or changes.

## Acknowledgments

Duplicity was written by Ben Escoto. It is now being maintained by Kenneth Loafman.

- <http://duplicity.nongnu.org/>
