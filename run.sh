#!/usr/bin/env bash

set -exEuo pipefail

docker run --rm \
    --env-file ./.env \
    --network=host \
    --volume ./dump:/dump \
    joshuachp/pg-backup-container:0.1.1
