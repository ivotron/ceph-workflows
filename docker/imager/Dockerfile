FROM docker:stable

RUN apk --no-cache add bash rsync

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
