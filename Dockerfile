FROM alpine:3.10

RUN apk update \
    && apk add \
        openssl \
        ca-certificates \
        fuse \
    && cd /tmp \
    && wget -q http://downloads.rclone.org/rclone-current-linux-amd64.zip \
    && unzip /tmp/rclone-current-linux-amd64.zip \
    && mv /tmp/rclone-*-linux-amd64/rclone /usr/bin \
    && rm -r /tmp/rclone*
    
RUN apk update && apk add borgbackup=1.1.10-r0 curl postgresql-client

WORKDIR /borg-rclone/
ADD *.sh /borg-rclone/
RUN chmod +x *.sh

ENTRYPOINT ["/borg-rclone/entrypoint.sh"]
