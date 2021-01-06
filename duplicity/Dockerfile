FROM alpine:3.12.3

WORKDIR /usr/src/app

# hadolint ignore=DL3018
RUN apk add --no-cache \
        ca-certificates \
        gettext \
        gnupg \
        lftp \
        libffi \
        librsync \
        libxml2 \
        libxslt \
        openssh \
        openssl \
        python3 \
        py3-six \
        rsync && \
    update-ca-certificates

COPY requirements.txt ./

# hadolint ignore=DL3018
RUN apk add --no-cache -t .build-deps \
        make gcc \
        libffi-dev \
        librsync-dev \
        libxml2-dev \
        libxslt-dev \
        musl-dev \
        openssl-dev \
        python3-dev \
        py3-pip \
        py3-setuptools && \
    pip install -r requirements.txt && \
    # pip install <missing-module> && pip freeze > requirements.txt && \
    apk del --purge .build-deps

COPY init.sh ./

RUN chmod +x init.sh

ENTRYPOINT [ "./init.sh" ]

CMD [ "--help" ]
