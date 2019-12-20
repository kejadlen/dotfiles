FROM armhf/alpine

RUN apk update && apk upgrade && \
    apk add curl

RUN curl --location --remote-name https://github.com/syncthing/syncthing/releases/download/v1.3.2/syncthing-linux-arm-v1.3.2.tar.gz && \
    tar xvz < syncthing-linux-arm-v1.3.2.tar.gz && \
    mv syncthing-linux-arm-v1.3.2/syncthing /usr/sbin && \
    mkdir /etc/syncthing

RUN adduser -D syncthing
USER syncthing

ENTRYPOINT [ "syncthing", "-gui-address=0.0.0.0:8384", "-home=/etc/syncthing" ]
