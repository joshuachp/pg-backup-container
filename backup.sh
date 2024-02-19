#!/usr/bin/env bash

set -exEuo pipefail

# Backup all postgres databases while sending notifications to Ntfy
#
# ENV:
# - NTFY_URL: url of the Ntfy server
# - NTFY_TOPIC: topic to notify on
# - HOST: postgres database host
# - PORT: postgres database port
# - PGPASSWORD: password to the postgres database
# - BACKUP_DIR: volume to backup into
# - BACKUP_COUNT: count of backups to keep in the BACKUP_DIR
# - OUTDIR: Directory to store the intermediate file

outfile="${OUTDIR:-.}/dump-$(date -Iseconds -u).sql.zstd"

panic() {
    if [ $? = '0' ]; then
        return
    fi

    status "Database backup failed" \
        "The database backup to $outfile failed" \
        5
}

trap "panic" ERR
trap "panic" EXIT

# Find the printf binary not the shell builtin
printf=$(command -v printf)

template='{
    "topic": "%s",
    "title": "%s",
    "message": "%s",
    "tags": ["backup"],
    "priority": %d
}'

status() {
    topic=$NTFY_TOPIC
    title=$1
    message=$2
    priority=${3:-3}

    payload=$($printf "$template" "$topic" "$title" "$message" "$priority")

    curl "$NTFY_URL" --json "$payload"
}

status \
    "Start DB backup" \
    "Starting database dump to $outfile"

if [[ -z $PGPASSWORD ]]; then
    echo "Missing password"
    exit 1
fi

if ! pg_dumpall --host "$HOST" --port "${PORT:-5432}" --username postgres -w | zstd >"$outfile"; then
    status "Database backup failed" \
        "The database dump to $outfile failed with status $?" \
        5
fi

status \
    "Dump DB backup" \
    "Database dumped successfully to $outfile" \
    2

mv "$outfile" "$BACKUP_DIR"

status \
    "Successful DB backup" \
    "Database completed successfully"

find "$BACKUP_DIR" -type f -name 'dump-*' |
    sort -r |
    tail -n "+${BACKUP_COUNT:-15}" |
    xargs -r rm

status \
    "Db cleanup" \
    "Database cleanup successfull" \
    1
