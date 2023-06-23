#!/usr/bin/env bash

set -o errexit -o nounset -o errtrace -o pipefail -x

if [[ "${IMAGE_NAME}" == "" ]]; then
    echo "Must set IMAGE_NAME environment variable. Exiting."
    exit 1
fi

docker run --rm \
    -v "/tmp/backup-repo:/repo" \
    "${IMAGE_NAME}" \
    --password-command "echo 'supersecret'" \
    -r /repo \
    init

docker run --rm \
    -v "/tmp/backup-repo:/repo" \
    "${IMAGE_NAME}" \
    --password-command "echo 'supersecret'" \
    -r /repo \
    backup /dev

docker run --rm \
    -v "/tmp/backup-repo:/repo" \
    "${IMAGE_NAME}" \
    --password-command "echo 'supersecret'" \
    -r /repo \
    stats

rm -rf /tmp/backup-repo
