FROM alpine:3.14.0

WORKDIR /usr/src/app

# hadolint ignore=DL3018
RUN apk add --no-cache bash curl jq openssh rsync

COPY *.sh ./

RUN chmod +x ./*.sh

ENV PATH "${PATH}:/usr/src/app"

CMD [ "/usr/src/app/run.sh" ]

ENV INTERVAL 4h
ENV WORKDIR /backups
ENV DATA_ROOT /mnt/data/docker/volumes
