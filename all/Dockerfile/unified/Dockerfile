FROM ubuntu:latest

ARG DEBIAN_FRONTEND=noninteractive
ARG TZ="Etc/GMT"
ARG CHOICE
ARG SSH_PUBLIC_KEY
ARG SSH_PRIVATE_KEY
ENV BUILD_DATE=${DATE}
ENV INSTALLATION_TYPE=docker
ENV WALLET=${WALLET}
ENV CONFIG_PASSWORD=${CONFIG_PASSWORD}

ARG FUN_HB_CLIENT_REPOSITORY_URL="${FUN_HB_CLIENT_REPOSITORY_URL:-https://github.com/funttastic/fun-hb-client.git}"
ARG FUN_HB_CLIENT_REPOSITORY_BRANCH="${FUN_HB_CLIENT_REPOSITORY_BRANCH:-community}"
ENV FUN_HB_CLIENT_PORT=${FUN_HB_CLIENT_PORT:-5000}
ENV FUN_HB_CLIENT_COMMAND="${FUN_HB_CLIENT_COMMAND:-echo}"
ENV FUN_HB_CLIENT_COMMIT_BRANCH=${FUN_HB_CLIENT_BRANCH}
ENV FUN_HB_CLIENT_COMMIT_SHA=${FUN_HB_CLIENT_COMMIT}
ENV FUN_HB_CLIENT_BUILD_DATE=${FUN_HB_CLIENT_BUILD_DATE}

ARG GATEWAY_REPOSITORY_URL=${GATEWAY_REPOSITORY_URL:-https://github.com/Team-Kujira/gateway.git}
ARG GATEWAY_REPOSITORY_BRANCH=${GATEWAY_REPOSITORY_BRANCH:-community}
ENV GATEWAY_PORT=${GATEWAY_PORT:-15888}
ENV GATEWAY_COMMAND=${GATEWAY_COMMAND:-echo}
ENV GATEWAY_COMMIT_BRANCH=${GATEWAY_BRANCH}
ENV GATEWAY_COMMIT_SHA=${GATEWAY_COMMIT}
ENV GATEWAY_BUILD_DATE=${GATEWAY_BUILD_DATE}

ARG HB_CLIENT_REPOSITORY_URL=${REPOSITORY_URL:-https://github.com/Team-Kujira/hummingbot.git}
ARG HB_CLIENT_REPOSITORY_BRANCH=${REPOSITORY_BRANCH:-community}
ENV STRATEGY=${STRATEGY}
ENV HB_CLIENT_CONFIG_FILE_NAME=${HB_CLIENT_CONFIG_FILE_NAME}
ENV HB_CLIENT_COMMIT_BRANCH=${HB_CLIENT_BRANCH}
ENV HB_CLIENT_COMMIT_SHA=${HB_CLIENT_COMMIT}
ENV HB_CLIENT_BUILD_DATE=${HB_CLIENT_BUILD_DATE}
ENV HB_CLIENT_COMMAND=${HB_CLIENT_COMMAND:-echo}

#ENV CONCATENATED_COMMAND="$FUN_HB_CLIENT_COMMAND; $GATEWAY_COMMAND; $HB_CLIENT_COMMAND"

LABEL hb_client_branch=${HB_CLIENT_BRANCH}
LABEL hb_client_commit=${HB_CLIENT_COMMIT}
LABEL hb_client_date=${HB_CLIENT_BUILD_DATE}

LABEL gateway_application="gateway-v2"
LABEL gateway_branch=${GATEWAY_BRANCH}
LABEL gateway_commit=${GATEWAY_COMMIT}
LABEL gateway_build_date=${GATEWAY_BUILD_DATE}

EXPOSE $FUN_HB_CLIENT_PORT
#EXPOSE $GATEWAY_PORT

WORKDIR /root

RUN :> /root/.bashrc

SHELL [ "/bin/bash", "-lc" ]

RUN <<-EOF
  set -ex

  apt-get update

  apt-get install --no-install-recommends -y \
    git \
    gcc \
    vim \
    tree \
    curl \
    psmisc \
    python3 \
    python3-pip \
    python3-dev \
    libusb-1.0 \
    libssl-dev \
    pkg-config \
    libsecret-1-0 \
    openssh-server \
    build-essential \
    ca-certificates \
    postgresql-server-dev-all

  set +ex
EOF

RUN echo "Starting Funttastic Hummingbot Client build process"

RUN <<-EOF
  set -ex

  unlink /usr/bin/pip
  ln -s /usr/bin/python3 /usr/bin/python
  ln -s /usr/bin/pip3 /usr/bin/pip

  set +ex
EOF

# Authorizing the ssh host
RUN <<-EOF
  if [[ "$SSH_PUBLIC_KEY" && "$SSH_PRIVATE_KEY" ]]; then \
    set -ex

    mkdir -p /root/.ssh
    chmod 0700 /root/.ssh
    ssh-keyscan github.com > /root/.ssh/known_hosts

    set +ex
  fi
EOF

# Adding the keys and setting the permissions
RUN <<-EOF
  if [[ "$SSH_PUBLIC_KEY" && "$SSH_PRIVATE_KEY" ]]; then \
    set -e
    set +x

    echo "$SSH_PRIVATE_KEY" > /root/.ssh/id_rsa

    set -ex

    echo "$SSH_PUBLIC_KEY" > /root/.ssh/id_rsa.pub
    chmod 600 /root/.ssh/id_rsa
    chmod 600 /root/.ssh/id_rsa.pub

    set +ex
  fi
EOF

RUN <<-EOF
  set -ex

  git clone -b $FUN_HB_CLIENT_REPOSITORY_BRANCH $FUN_HB_CLIENT_REPOSITORY_URL /tmp/funttastic
  mkdir -p funttastic/client
  cp -a /tmp/funttastic/. funttastic/client
  rm -rf /tmp/funttastic

  set +ex
EOF

RUN <<-EOF
  set -ex

  mkdir -p funttastic/client/resources/certificates
  cp funttastic/client/resources/configuration/production.example.yml funttastic/client/resources/configuration/production.yml
  cp -R funttastic/client/resources/strategies/templates/* funttastic/client/resources/strategies

  set +ex
EOF

RUN <<-EOF
  set -ex

  mv funttastic/client/resources funttastic/client/resources_temp

  set +ex
EOF

RUN echo "Ending Funttastic Hummingbot Client build process"

RUN echo "Starting Hummingbot Gateway build process"

RUN <<-EOF
	set -ex

	git clone -b $GATEWAY_REPOSITORY_BRANCH $GATEWAY_REPOSITORY_URL /tmp/hummingbot/gateway
	mkdir -p hummingbot/gateway
	cp -a /tmp/hummingbot/gateway/. hummingbot/gateway

  set +ex
EOF

RUN <<-EOF
	set -ex

	mkdir -p \
		hummingbot/gateway/certs \
		hummingbot/gateway/db \
		hummingbot/gateway/conf \
		hummingbot/gateway/logs \
		/var/lib

	set +ex
EOF

RUN <<-EOF
  set -ex

  cp -R hummingbot/gateway/src/templates/. hummingbot/gateway/conf

  set +ex
EOF

# Install nvm and CeloCLI; note: nvm adds own section to /root/.bashrc
RUN <<-EOF
	set -ex

	curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

  export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

	nvm install 16.3.0
	nvm use 16.3.0
	nvm cache clear

#	if [ ! "$ARCHITECTURE" == "aarch64" ]
#	then
#		npm install --unsafe-perm --only=production -g @celo/celocli@1.0.3
#	fi

	npm install --global yarn
	npm cache clean --force

	rm -rf /root/.cache

	set +ex
EOF

RUN <<-EOF
	set -ex

  cd hummingbot/gateway
	yarn
	yarn prebuild
	yarn build

	set +ex
EOF

RUN echo "Ending Hummingbot Gateway build process"

RUN echo "Starting Hummingbot Client build process"

RUN <<-EOF
	set -ex

	mkdir -p hummingbot/client

  set +ex
EOF

WORKDIR /root/hummingbot/client

RUN <<-EOF
	set -ex

	git clone -b $HB_CLIENT_REPOSITORY_BRANCH $HB_CLIENT_REPOSITORY_URL /tmp/hummingbot/client
	cp -a /tmp/hummingbot/client/. .

  rm -rf /tmp/hummingbot

  set +ex
EOF

# Install miniconda
RUN <<-EOF
	set -ex

	ARCHITECTURE="$(uname -m)"

	case $(uname | tr '[:upper:]' '[:lower:]') in
		linux*)
			OS="Linux"
			FILE_EXTENSION="sh"
			case $(uname -r	| tr '[:upper:]' '[:lower:]') in
			*raspi*)
				IS_RASPBERRY="TRUE"
				;;
			*)
				IS_RASPBERRY="FALSE"
				;;
			esac
			;;
		darwin*)
			OS="MacOSX"
			FILE_EXTENSION="sh"
			;;
		msys*)
			OS="Windows"
			FILE_EXTENSION="exe"
			;;
		*)
			echo "Unrecognized OS"
			exit 1
			;;
	esac

	echo "export ARCHITECTURE=$ARCHITECTURE" >> /root/.bashrc
	echo "export OS=$OS" >> /root/.bashrc
	echo "export FILE_EXTENSION=$FILE_EXTENSION" >> /root/.bashrc
	echo "export IS_RASPBERRY=$IS_RASPBERRY" >> /root/.bashrc

	if [ "$ARCHITECTURE" == "aarch64" ]
	then
		echo "export ARCHITECTURE_SUFFIX=\"-$ARCHITECTURE\"" >> /root/.bashrc
		MINICONDA_VERSION="Mambaforge-$(uname)-$(uname -m).sh"
		MINICONDA_URL="https://github.com/conda-forge/miniforge/releases/latest/download/$MINICONDA_VERSION"
		ln -s /root/mambaforge /root/miniconda3
	else
		MINICONDA_VERSION="Miniconda3-py38_4.10.3-$OS-$ARCHITECTURE.$FILE_EXTENSION"
		MINICONDA_URL="https://repo.anaconda.com/miniconda/$MINICONDA_VERSION"
	fi

	curl -L "$MINICONDA_URL" -o "/root/miniconda.$MINICONDA_EXTENSION"
	/bin/bash "/root/miniconda.$MINICONDA_EXTENSION" -b
	rm "/root/miniconda.$MINICONDA_EXTENSION"
	/root/miniconda3/bin/conda update -n base conda -y
	/root/miniconda3/bin/conda clean -tipy

	echo "export MINICONDA_VERSION=$MINICONDA_VERSION" >> /root/.bashrc
	echo "export MINICONDA_URL=$MINICONDA_URL" >> /root/.bashrc

	set +ex
EOF

RUN <<-EOF
	set -ex

	MINICONDA_ENVIRONMENT=$(head -1 setup/environment.yml | cut -d' ' -f2)
	if [ -z "$MINICONDA_ENVIRONMENT" ]
	then
		echo "The MINICONDA_ENVIRONMENT environment variable could not be defined."
		exit 1
	fi
	echo "export MINICONDA_ENVIRONMENT=$MINICONDA_ENVIRONMENT" >> /root/.bashrc

	/root/miniconda3/bin/conda env create -f setup/environment.yml
	/root/miniconda3/bin/conda clean -tipy
	rm -rf /root/.cache

	set +ex
EOF

RUN <<-EOF
	set -ex

	echo "source /root/miniconda3/etc/profile.d/conda.sh && conda activate $MINICONDA_ENVIRONMENT" >> /root/.bashrc
	/root/miniconda3/envs/$MINICONDA_ENVIRONMENT/bin/python3 setup.py build_ext --inplace -j 8
	rm -rf build/
	find . -type f -name "*.cpp" -delete

	set +ex
EOF

RUN <<-EOF
	set -ex

	mkdir -p \
  	certs \
  	conf/connectors \
  	conf/strategies \
  	conf/scripts \
  	logs \
  	data \
  	scripts \
  	pmm_scripts

	set +ex
EOF

WORKDIR /root

RUN echo "Ending Hummingbot Client build process"

CMD ["sh", "-c", "$FUN_HB_CLIENT_COMMAND; $GATEWAY_COMMAND; $HB_CLIENT_COMMAND"]
