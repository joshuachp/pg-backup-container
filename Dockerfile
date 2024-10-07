FROM postgres:17.0-alpine3.20

RUN apk add --no-cache \
        age \
        bash \
        curl \
        zstd

COPY ./backup.sh /usr/bin/backup.sh

ENTRYPOINT ["/usr/bin/backup.sh"]
