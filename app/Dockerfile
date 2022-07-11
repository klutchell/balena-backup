
# https://hub.docker.com/_/golang
FROM golang:1.18.2-alpine3.14 AS restic

# hadolint ignore=DL3018
RUN apk add --no-cache build-base curl git

WORKDIR /usr/src/app

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

# restic is available in the alpine repos and it has a self-update function
# but we want to build from source so we can get a specific release
# https://restic.readthedocs.io/en/v0.13.1/020_installation.html
ARG RESTIC_RELEASE=0.13.1
ARG RESTIC_SHA256=8430f80dc17b98fd78aca6f7d635bf12a486687677e15989a891ff4f6d8490a9

RUN curl -fsSL -o restic.tar.gz \
    https://github.com/restic/restic/releases/download/v${RESTIC_RELEASE}/restic-${RESTIC_RELEASE}.tar.gz && \
    echo "${RESTIC_SHA256}  restic.tar.gz" | sha256sum -c - && \
    tar -xzf restic.tar.gz --strip 1 && \
    rm restic.tar.gz && \
    go run build.go
    
# https://hub.docker.com/_/alpine
FROM alpine:3.14.3

# hadolint ignore=DL3018
RUN apk add --no-cache ca-certificates fuse openssh rclone bash blkid curl rsync jq tzdata util-linux coreutils

COPY --from=restic /usr/src/app/restic /usr/bin/restic

RUN restic version

WORKDIR /usr/src/app

COPY *.sh ./
RUN chmod +x ./*.sh

CMD [ "/usr/src/app/run.sh" ]

ENV DEVICE_DATA_ROOT "/mnt/data/docker/volumes"
ENV BACKUP_CRON "0 */8 * * *"

ENV RESTIC_PASSWORD "balena"
ENV RESTIC_REPOSITORY "/backups"

ENV CACHE_ROOT "/cache"
ENV RESTIC_CACHE_DIR "/cache/restic"
