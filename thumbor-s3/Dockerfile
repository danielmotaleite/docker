# Working thumbor-s3/riak setup, you can drop all capabilities in docker
# just change some parameters, like the TC_AWS_ENDPOINT, start docker with the vault token and environment
# and test:  curl http://thumbor-s3:9990/unsafe/fit-in/220x220/filters:fill(white)/bucket-name/path/123.jpg
# you can later auto-add the bucket name in nginx, using map and rewrite.
# after tests, you can secure thumbor by disabling ALLOW_UNSAFE_URL
# Based on the work by Luís Almeida and tcaxias

FROM alpine:edge
MAINTAINER Daniel Mota Leite http://github.com/danielmotaleite
WORKDIR /app

EXPOSE 9990
EXPOSE 9901

ENV \
    PKGS="py2-pip py-curl jpeg zlib curl" \
    DEPS="build-base python-dev zlib-dev jpeg-dev" \
    THUMBOR_INSTANCES="1"

RUN apk update && \
    apk upgrade && \
    apk add --update $DEPS $PKGS && \
    pip install thumbor tc_aws tc_prometheus && \
    apk del $DEPS && \
    rm -rf /var/cache/apk/*

ADD thumbor.conf thumbor.sh /app/

# make sure user nobody can write this files
RUN touch        /app/thumbor.conf /app/thumbor.key /app/aws.credentials && \
    chown nobody /app/thumbor.conf /app/thumbor.key /app/aws.credentials /app

USER nobody

CMD [ "./thumbor.sh"]

ENV TERM="xterm"
