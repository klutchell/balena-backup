# balena-backup

non-interactive backup utility for balenaCloud managed devices

## Requirements

- one or more devices managed via [balenaCloud](https://www.balena.io/cloud/)
- linux workstation or backup server with [balena CLI](https://www.balena.io/docs/reference/balena-cli/)

## Getting Started

Make sure you have ssh access to the HostOS of your balenaCloud devices.

- <https://www.balena.io/docs/learn/manage/ssh-access/#using-a-standalone-ssh-client>

> If you prefer to use a standalone SSH client to connect to the device, the SSH server on a device listens on TCP port 22222. While development images have passwordless root access enabled, production images require an SSH key to be added to the config.json file.

I personally added SSH keys to my Production images via the [configizer project](https://github.com/balena-io-playground/configizer). Other options are outlined here.

- <https://www.balena.io/docs/reference/OS/configuration>

## Deployment

Once your SSH keys are up, deployment is carried out by downloading or cloning the project and running it while passing in a local destination directory of your choosing.

## Environment Variables

| Name                   | Default                   | Purpose                                        |
| ---------------------- | ------------------------- | ---------------------------------------------- |
| `BALENA_TOKEN`         |                           | optional token for balena login                |
| `BALENA_EMAIL`         |                           | optional credentials for balena login          |
| `BALENA_PASSWORD`      |                           | optional credentials for balena login          |
| `BACKUP_DEST`          | `$HOME/balenaCloud`       | local backup folder destination                |
| `BALENA_DEVICES`       |                           | optional balenaCloud managed devices UUID list |
| `MYSQL_ROOT_PASSWORD`  |                           | root password for dumping mysql databases      |
| `MYSQL_DUMP_FILE`      | `/var/lib/mysql/dump.sql` | temporary file for the mysql database dump     |
| `RSYNC_CONTAINER_NAME` | `rsync_backup`            | name of the temporary rsync backup container   |
| `RSYNC_CONTAINER_WAIT` | `600`                     | seconds until rsync container is removed       |
| `RSYNC_LOCAL_PORT`     | `4321`                    | local port for temporary ssh tunnel            |

## Usage

This utility will perform the following tasks in order for each balenaCloud managed device.

1. parse a list of any mysql services on device
2. for each service from the previous step dump the mysql database to a file
3. parse a list of all non-dangling persistent volumes
4. start an rsync backup container and mount all volumes from the previous step
5. sleep container for x seconds while remaining steps are performed
6. disconnect from the device and return to workstation shell
7. start a new tunnel from localhost port 1234 to remote device 22222 (ssh)
8. use rsync to mirror all sources (volumes) from the rsync backup container to a local directory

Note the example destination dir of `~/balenaCloud`. Subfolders will be created for each device UUID.

```bash
export MYSQL_ROOT_PASSWORD=********
export BALENA_TOKEN=********************************
./backup.sh ~/balenaCloud
```

## Contributing

Please open an issue or submit a pull request with any features, fixes, or changes.

## Author

Kyle Harding <https://klutchell.dev>

[Buy me a beer](https://kyles-tip-jar.myshopify.com/cart/31356319498262:1?channel=buy_button)

[Buy me a craft beer](https://kyles-tip-jar.myshopify.com/cart/31356317859862:1?channel=buy_button)

## Acknowledgments

- <https://github.com/balena-io/configizer>
- <https://forums.balena.io/t/balena-cli-ssh-non-interactively-into-running-service/105219>
- <https://www.balena.io/docs/learn/manage/ssh-access/#using-balena-ssh-from-the-cli>
- <https://forums.balena.io/t/rsync-over-balena-ssh-tunnel/6228/4>

## License

[MIT License](./LICENSE)
