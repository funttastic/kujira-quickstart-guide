FROM ubuntu:latest

ARG DEBIAN_FRONTEND=noninteractive
ARG TZ="Etc/GMT"
ARG SSH_PUBLIC_KEY
ARG SSH_PRIVATE_KEY
ARG REPOSITORY_URL="${REPOSITORY_URL:-git@github.com:funttastic/fun-hb-client.git}"
ARG REPOSITORY_BRANCH="${REPOSITORY_BRANCH:-production}"

ENV PORT="${PORT:-5000}"

WORKDIR /root

RUN set -ex \
  && apt-get update \
  && apt-get install --no-install-recommends -y \
    ca-certificates \
    openssh-server \
    git \
    python3 \
    python3-pip \
    postgresql-server-dev-all \
    build-essential \
    python3-dev \
#  && apt clean \
#  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
#	&& unlink /usr/bin/python \
	&& unlink /usr/bin/pip \
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
  && git clone -b $REPOSITORY_BRANCH $REPOSITORY_URL /tmp/app \
  && mv /tmp/app/* . \
  && rm -rf /tmp/app \
  && pip install -r requirements.txt \
  && set +ex

# Needs to coincide with what's defined inside of the configuration file.
EXPOSE $PORT

CMD python app.py
