#!/usr/bin/env bash

set -exEuo pipefail

tag=$(
    git tag |
        sort --version-sort |
        tail -n 1 |
        sed -r 's/v([0-9]+\.[0-9]+\.[0-9]+)/\1/'
)

docker buildx build \
    --builder=container \
    --platform=linux/amd64,linux/arm64 \
    -t "joshuachp/pg-backup-container:$tag" \
    "$@" .
