# pg-backup-container

Backup a PostgreSQL database via pg_dump to a different volume

```
ENV:
- NTFY_URL: url of the Ntfy server
- NTFY_TOPIC: topic to notify on
- HOST: postgres database host
- PORT: postgres database port
- PGPASSWORD: password to the postgres database
- BACKUP_DIR: volume to backup into
- BACKUP_COUNT: count of backups to keep in the BACKUP_DIR
- OUTDIR: Directory to store the intermediate file
- PUB_KEY: Public age key to encrypt the backup with
```
