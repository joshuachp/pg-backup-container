#!/usr/bin/env bash

set -exEuo pipefail

# Backup all postgres databases while sending notifications to Ntfy
#
# ENV:
# - NTFY_URL: url of the Ntfy server
# - NTFY_TOPIC: topic to notify on
# - HOST: postgres database host
# - PORT: postgres database port
# - USERNAME: username to use, default to postgres
# - PGPASSWORD: password to the postgres database
# - BACKUP_DIR: volume to backup into
# - BACKUP_COUNT: count of backups to keep in the BACKUP_DIR
# - OUTDIR: Directory to store the intermediate file
# - PUB_KEY: Public age key to encrypt the backup with

outfile="${OUTDIR:-.}/dump-$(date -Iseconds -u).sql.zstd"

panic() {
    local st=$?
    if [ $st = '0' ]; then
        return
    fi

    status "Database backup failed" \
        "The database backup to $outfile failed" \
        5

    # Force cleanup
    rm -f "$outfile" || true

    exit $st
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

# Dump all database, encrypt the dump and zstd compress it
pg_dumpall --host "$HOST" --port "${PORT:-5432}" --username "${USERNAME:-postgres}" -w |
    age --encrypt -r "$PUB_KEY" |
    zstd >"$outfile"
st=$?
if [ $st != '0' ]; then
    status "Database backup failed" \
        "The database dump to $outfile failed with status $st" \
        5
    exit $st
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
