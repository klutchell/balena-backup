FROM alpine:3.12.3

WORKDIR /usr/src/app

# hadolint ignore=DL3018
RUN apk add --no-cache bash openssh rsync && \
    sed -e 's/^root:!:/root::/' -i /etc/shadow && \
    sed -e 's/#PasswordAuthentication.*/PasswordAuthentication no/' \
        -e 's/AuthorizedKeysFile.*/AuthorizedKeysFile \/keys\/authorized_keys/' \
        -i /etc/ssh/sshd_config

COPY init.sh ./

RUN chmod +x ./init.sh

CMD [ "./init.sh"]
