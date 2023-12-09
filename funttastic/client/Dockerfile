FROM ubuntu:latest

ARG DEBIAN_FRONTEND=noninteractive
ARG TZ="Etc/GMT"
ARG SSH_PUBLIC_KEY
ARG SSH_PRIVATE_KEY
ARG REPOSITORY_URL="${REPOSITORY_URL:-git@github.com:funttastic/fun-hb-client.git}"
ARG REPOSITORY_BRANCH="${REPOSITORY_BRANCH:-community}"

ENV PORT=${PORT:-5000}
ENV PASSWORD="${PASSWORD}"

WORKDIR /root

RUN <<-EOF
	set -ex

  apt-get update

  apt-get install --no-install-recommends -y \
    ca-certificates \
    openssh-server \
    git \
    python3 \
    python3-pip \
    postgresql-server-dev-all \
    build-essential \
    python3-dev \
		vim \
		tree \
		psmisc

  set +ex
EOF

RUN <<-EOF
	set -ex

	#	unlink /usr/bin/python
	unlink /usr/bin/pip
  ln -s /usr/bin/python3 /usr/bin/python
  ln -s /usr/bin/pip3 /usr/bin/pip

  set +ex
EOF

# Authorizing the ssh host
RUN <<-EOF
	set -ex

	mkdir -p /root/.ssh
  chmod 0700 /root/.ssh
  ssh-keyscan github.com > /root/.ssh/known_hosts

  set +ex
EOF

# Adding the keys and setting the permissions
RUN <<-EOF
	set -e
	set +x

	echo "$SSH_PRIVATE_KEY" > /root/.ssh/id_rsa

	set -ex

  echo "$SSH_PUBLIC_KEY" > /root/.ssh/id_rsa.pub
  chmod 600 /root/.ssh/id_rsa
  chmod 600 /root/.ssh/id_rsa.pub

  set +ex
EOF

RUN <<-EOF
	set -ex

	git clone -b $REPOSITORY_BRANCH $REPOSITORY_URL /tmp/app
  cp -a /tmp/app/. .
  rm -rf /tmp/app
  pip install -r requirements.txt

  set +ex
EOF

# Needs to coincide with what's defined inside of the configuration file.
EXPOSE $PORT

#RUN <<-EOF
#	set -ex
#
#	apt autoremove -y
#
#	apt clean autoclean
#
#	rm -rf \
#		/var/lib/apt/lists/* \
#		/etc/apt/sources.list \
#		/etc/apt/sources.list.d/* \
#		/tmp/* \
#		/var/tmp/*
#
#	set +ex
#EOF

CMD python app.py
