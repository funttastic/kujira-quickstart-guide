# Usage:
#   # The --squash option for `docker build` would be good, but it is not available in `buildx` yet and `build` requires to enable experimental features
#   docker buildx build --no-cache --build-arg SSH_PRIVATE_KEY="$(cat ~/.ssh/id_rsa)" --build-arg SSH_PUBLIC_KEY="$(cat ~/.ssh/id_rsa.pub)" -t <template> .
#   docker run -dt --name=<template> -p <exposed port>:5000 -v /path/to/shared/folder:/media/shared <template>
#   curl -d '{}' -H "Content-Type: application/json" -X POST http://localhost:<exposed port>/

FROM ubuntu:latest

ARG DEBIAN_FRONTEND=noninteractive
ARG TZ="Etc/GMT"

ARG SSH_PRIVATE_KEY
ARG SSH_PUBLIC_KEY

ENV PORT="${PORT:-5000}"

RUN set -ex \
  && apt-get update \
  && apt-get install --no-install-recommends -y \
    ca-certificates \
    openssh-server \
    git \
    python3 \
    python3-pip \
#  && apt clean \
#  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && ln -s /usr/bin/python3 /usr/bin/python \
  && ln -s /usr/bin/pip3 /usr/bin/pip \
  && set +ex

# Authorizing the ssh host
RUN set -ex \
  && mkdir -p /root/.ssh \
  && chmod 0700 /root/.ssh \
  && ssh-keyscan github.com > /root/.ssh/known_hosts \
  && set +ex

# Adding the keys and setting the permissions
RUN \
  echo "$SSH_PRIVATE_KEY" > /root/.ssh/id_rsa \
  && echo "$SSH_PUBLIC_KEY" > /root/.ssh/id_rsa.pub \
  && set -ex \
  && chmod 600 /root/.ssh/id_rsa \
  && chmod 600 /root/.ssh/id_rsa.pub \
  && set +ex

RUN set -ex \
  && mkdir -p /media/shared \
  && git clone -b $CLONE_BRANCH git@github.com:funttastic/fun-hb-client.git /tmp/app \
  && mkdir /root/app \
  && mv /tmp/app/* /root/app/ \
  && rm -rf /tmp/app \
  && cd /root/app \
  && pip install -r requirements.txt \
  && set +ex

WORKDIR /root/app

# Needs to coincide with what's defined inside of the configuration file.
EXPOSE $PORT

CMD \
  cp -R /media/shared/resources resources \
  && python app.py
