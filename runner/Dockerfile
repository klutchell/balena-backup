FROM alpine:3.14.2

WORKDIR /usr/src/app

# hadolint ignore=DL3018
RUN apk add --no-cache bash blkid curl jq openssh rsync

COPY *.sh ./

RUN chmod +x ./*.sh

CMD [ "/usr/src/app/run.sh" ]

ENV INTERVAL 4h
ENV LOCAL_BACKUPS /backups
ENV DATA_ROOT /mnt/data/docker/volumes
