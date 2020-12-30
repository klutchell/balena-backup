FROM node:12

WORKDIR /usr/src/app

# hadolint ignore=DL3016
RUN npm install balena-cli -g --production --unsafe-perm

# hadolint ignore=DL3008
RUN apt-get update && \
    apt-get install -yy --no-install-recommends \
    busybox-static curl jq gettext-base openssh-client && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY *.sh ./

RUN chmod +x ./*.sh

ENV PATH "${PATH}:/usr/src/app"

# set some defaults in case they are not set as tags
ENV DOCKER_IMAGE "docker.io/klutchell/duplicity:latest"
ENV BACKUP_SCHEDULE "0 0 * * *"
ENV BACKUP_URL "file:///backups/"
ENV BACKUP_VOLUMES "all"
ENV MOUNT_MODE "ro"

ENTRYPOINT [ "./init.sh" ]

CMD [ "./cron.sh" ]
