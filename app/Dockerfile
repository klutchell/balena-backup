# https://hub.docker.com/_/golang
FROM golang:1.17.1-alpine3.14 AS autorestic

# hadolint ignore=DL3018
RUN apk add --no-cache build-base curl git

WORKDIR /usr/src/app

ARG AUTORESTIC_RELEASE=1.2.0

RUN curl -fsSL -o autorestic.tar.gz \
    https://github.com/cupcakearmy/autorestic/archive/refs/tags/v${AUTORESTIC_RELEASE}.tar.gz && \
    tar -xzf autorestic.tar.gz --strip 1 && \
    rm autorestic.tar.gz && \
    go build -o autorestic main.go

# https://hub.docker.com/_/alpine
FROM alpine:3.14.2 AS run

# hadolint ignore=DL3018
RUN apk add --no-cache ca-certificates fuse openssh rclone restic bash blkid curl rsync jq yq tzdata

COPY --from=autorestic /usr/src/app/autorestic /usr/bin/

RUN restic version && autorestic --version && rclone --version

WORKDIR /usr/src/app

COPY *.sh ./
RUN chmod +x ./*.sh

CMD [ "/usr/src/app/run.sh" ]

ENV DEVICE_DATA_ROOT "/mnt/data/docker/volumes"
ENV BACKUP_CRON "0 */8 * * *"

# https://restic.readthedocs.io/en/stable/030_preparing_a_new_repo.html#local
# leave BACKEND_PATH empty to use named volume or usb storage automatically
ENV BACKEND_NAME "default"
ENV BACKEND_TYPE "local"
ENV BACKEND_PATH ""

# https://restic.readthedocs.io/en/stable/030_preparing_a_new_repo.html#backblaze-b2
# ENV BACKEND_TYPE "b2"
# ENV BACKEND_PATH "backblaze_bucketID"
# ENV B2_ACCOUNT_ID: "backblaze_keyID"
# ENV B2_ACCOUNT_KEY: "backblaze_applicationKey"

# https://restic.readthedocs.io/en/stable/030_preparing_a_new_repo.html#amazon-s3
# ENV BACKEND_TYPE "s3"
# ENV BACKEND_PATH "s3.amazonaws.com/bucket_name"
# ENV AWS_ACCESS_KEY_ID "my_key"
# ENV AWS_SECRET_ACCESS_KEY "my_secret"

# https://restic.readthedocs.io/en/stable/030_preparing_a_new_repo.html#minio-server
# ENV BACKEND_TYPE "s3"
# ENV BACKEND_PATH "http://localhost:9000/restic"
# ENV AWS_ACCESS_KEY_ID "my_key"
# ENV AWS_SECRET_ACCESS_KEY "my_secret"
