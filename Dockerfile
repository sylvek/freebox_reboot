FROM alpine:latest
RUN apk add --no-cache jq httpie openssl bash xxd
COPY reboot.sh /reboot.sh
ENTRYPOINT [ "bash" ]
CMD [ "/reboot.sh" ]