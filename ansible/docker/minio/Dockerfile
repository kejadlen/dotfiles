FROM armhf/alpine

RUN apk update && apk upgrade && \
    apk add curl

RUN curl --location --remote-name https://dl.min.io/server/minio/release/linux-arm/minio && \
    chmod +x minio && \
    mv minio /usr/sbin

EXPOSE 9000
VOLUME /data

ENTRYPOINT [ "minio", "server", "/data" ]
