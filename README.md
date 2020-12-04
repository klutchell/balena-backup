# balena-backup

non-interactive backup utility for balenaCloud managed devices

## Requirements

- one or more devices managed via [balenaCloud](https://www.balena.io/cloud/)

## Getting Started

This utility will perform the following tasks in order for each balenaCloud managed device.

1. parse a list of all non-dangling persistent volumes
2. create a temporary container and mount all volumes from the previous step
3. create a new tunnel from localhost to the remote device ssh port
4. use rsync to mirror all sources (volumes) from the temporary container to a local volume

This process requires an API Key generated on the balenaCloud Dashboard.

<https://dashboard.balena-cloud.com/preferences/access-token>

Once your key has been generated, keep it somewhere safe as you'll need it for future steps.

## Deployment

Deployment is carried out by downloading or cloning the project and running docker build.

## Usage

```bash
docker build . -t balena-backup
docker run --rm \
    -e "BALENA_API_KEY=********************************" \
    -e "BALENA_DEVICES=foo bar" \
    -v "${HOME}/.balenaCloud:/backups" \
    balena-backup
```

## Environment Variables

| Name             | Default | Purpose                                                                               |
| ---------------- | ------- | ------------------------------------------------------------------------------------- |
| `BALENA_API_KEY` |         | API key for balena CLI (https://dashboard.balena-cloud.com/preferences/access-tokens) |
| `BALENA_DEVICES` | all     | space-sparated list of device UUIDs to backup                                         |
| `BACKUP_TIMEOUT` | `600`   | seconds until temporary container is removed                                          |
| `TUNNEL_PORT`    | `54321` | local port for temporary ssh tunnel                                                   |

## Contributing

Please open an issue or submit a pull request with any features, fixes, or changes.

## Acknowledgments

- <https://github.com/balena-io/configizer>
- <https://forums.balena.io/t/balena-cli-ssh-non-interactively-into-running-service/105219>
- <https://www.balena.io/docs/learn/manage/ssh-access/#using-balena-ssh-from-the-cli>
- <https://forums.balena.io/t/rsync-over-balena-ssh-tunnel/6228/4>
