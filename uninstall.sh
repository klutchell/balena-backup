#!/bin/sh

balena stop "${CONTAINER_NAME}" 2>/dev/null

mv /home/root/.ssh/authorized_keys.orig /home/root/.ssh/authorized_keys 2>/dev/null

exit
