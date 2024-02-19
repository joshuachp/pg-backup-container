FROM alpine:3.19.1

RUN apk add --no-cache \
        curl \
        postgresql-client

COPY ./backup.sh /usr/bin/backup.sh

ENTRYPOINT ["/usr/bin/backup.sh"]
