#!/bin/sh

export DOCKER_CLI_EXPERIMENTAL=enabled

docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

docker buildx build . \
    --platform linux/amd64,linux/arm64,linux/arm/v7,linux/arm/v6 \
    --tag "klutchell/duplicity:$(date '+%Y%m%d')" \
    --tag "klutchell/duplicity:latest" \
    --pull --push
