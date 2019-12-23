FROM arm32v7/alpine:latest

COPY minio /usr/sbin

EXPOSE 9000
VOLUME /data

ENTRYPOINT [ "minio", "server", "/data" ]
