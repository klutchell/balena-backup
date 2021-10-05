# https://hub.docker.com/_/alpine
FROM alpine:3.14.2

# hadolint ignore=DL3018
RUN apk add --no-cache ca-certificates fuse openssh rclone restic bash blkid curl rsync jq tzdata

WORKDIR /usr/src/app

RUN restic self-update

COPY *.sh ./
RUN chmod +x ./*.sh

CMD [ "/usr/src/app/run.sh" ]

ENV DEVICE_DATA_ROOT "/mnt/data/docker/volumes"
ENV BACKUP_CRON "0 */8 * * *"
