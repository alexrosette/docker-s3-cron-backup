FROM alpine:latest

RUN apk -Uuv add busybox-suid less aws-cli curl docker-cli && \
	rm /var/cache/apk/*

COPY entrypoint.sh /
COPY dobackup.sh /

RUN chmod +x /entrypoint.sh /dobackup.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD [ "crond", "-f", "-d", "8" ]
