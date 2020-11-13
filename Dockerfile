FROM node:12

RUN npm install balena-cli@v12.27.3 -g --production --unsafe-perm

RUN apt-get update && \
    apt-get install -yy --no-install-recommends \
    openssh-client rsync jq gettext-base && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV BACKUP_DESTDIR "/backups"
ENV BACKUP_TIMEOUT "600"
ENV TUNNEL_PORT "54321"

COPY backup.sh install.sh uninstall.sh rsync.rsh /

RUN chmod +x /backup.sh

RUN balena --version

CMD [ "/backup.sh" ]