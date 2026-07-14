#!/bin/sh

update-ca-certificates
rq worker --path /opt/occ \
    --url redis://${REDIS_HOST}:6379 \
    --date-format='%Y-%m-%d %H:%M:%S' \
    ${RQ_TARGET_QUEUE_NAME:-default}