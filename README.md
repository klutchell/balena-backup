# balena-backup

non-interactive backup utility for balenaCloud managed devices

## Planned Rework

- Run entire pipeline in a ephemeral local container w/ balena cli
- Remove database export steps and focus on primary objective
- Avoid requirement for ssh keys on production device hostOS (use balena tunnel)
- Create remote ssh server with internal port 12345 (not public)
- Use balena tunnel to connect to ssh server port
- Rsync files from all remote volumes to local directory
- Clean up local container

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

| Name             | Default | Purpose                                                                               |
| ---------------- | ------- | ------------------------------------------------------------------------------------- |
| `BALENA_API_KEY` |         | API key for balena CLI (https://dashboard.balena-cloud.com/preferences/access-tokens) |
| `BALENA_DEVICES` | all     | space-sparated list of device UUIDs to backup                                         |
| `BACKUP_TIMEOUT` | `600`   | seconds until temporary container is removed                                          |
| `TUNNEL_PORT`    | `54321` | local port for temporary ssh tunnel                                                   |

## Usage

This utility will perform the following tasks in order for each balenaCloud managed device.

1. parse a list of all non-dangling persistent volumes
2. create a temporary container and mount all volumes from the previous step
3. start a private ssh server and sleep for x seconds while remaining steps are performed
4. create a new tunnel from localhost to remote device private ssh port
5. use rsync to mirror all sources (volumes) from the temporary container to a local volume

```bash
docker build . -t balena-backup
docker run --rm \
    -e "BALENA_API_KEY=********************************" \
    -e "BALENA_DEVICES=foo bar" \
    -v "${HOME}/.balenaCloud:/backups" \
    balena-backup
```

## Contributing

Please open an issue or submit a pull request with any features, fixes, or changes.

## Acknowledgments

- <https://github.com/balena-io/configizer>
- <https://forums.balena.io/t/balena-cli-ssh-non-interactively-into-running-service/105219>
- <https://www.balena.io/docs/learn/manage/ssh-access/#using-balena-ssh-from-the-cli>
- <https://forums.balena.io/t/rsync-over-balena-ssh-tunnel/6228/4>
