#!/bin/bash

set -eu

/usr/src/app/update-crontab.sh

_term() { 
    kill -TERM "${CRON_PID}" 2>/dev/null
}

trap _term SIGINT SIGTERM

# execute cron in the background with logging to stdout
exec busybox crond -f -l 0 -L /dev/stdout &

# then attach to it so we can trap SIGINT and SIGKILL messages
CRON_PID="$!"
wait "${CRON_PID}"
