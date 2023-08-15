# syntax=docker/dockerfile-upstream:1-labs
FROM ubuntu:20.04

ARG BRANCH=""
ARG COMMIT=""
ARG BUILD_DATE=""
LABEL branch=${BRANCH}
LABEL commit=${COMMIT}
LABEL date=${BUILD_DATE}

# Set ENV variables
ENV COMMIT_SHA=${COMMIT}
ENV COMMIT_BRANCH=${BRANCH}
ENV BUILD_DATE=${DATE}

ENV CLONE_BRANCH=${CLONE_BRANCH:-production}
ENV STRATEGY=${STRATEGY}
ENV CONFIG_FILE_NAME=${CONFIG_FILE_NAME}
ENV WALLET=${WALLET}
ENV CONFIG_PASSWORD=${CONFIG_PASSWORD}

ENV INSTALLATION_TYPE=docker

ARG DEBIAN_FRONTEND=noninteractive
ARG TZ="Etc/GMT"

WORKDIR /root

# Dropping default /root/.bashrc because it will return if not running as interactive shell, thus not invoking PATH settings
RUN :> /root/.bashrc

SHELL [ "/bin/bash", "-lc" ]

RUN <<-EOF
	apt-get update

	apt-get install --no-install-recommends -y \
		ca-certificates \
		openssh-server \
		gcc \
		libusb-1.0 \
		build-essential \
		pkg-config \
		libusb-1.0 \
		libsecret-1-0 \
		libssl-dev \
		curl \
		python3 \
		git
EOF

RUN <<-EOF
	git clone -b $CLONE_BRANCH https://github.com/funttastic/hummingbot-client.git temporary
	cp -r temporary/* .
	rm -rf temporary
EOF
# COPY . .

# Install miniconda
RUN <<-EOF
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
EOF

# Install nvm and CeloCLI; note: nvm adds own section to /root/.bashrc
RUN <<-EOF
	curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
	NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
	[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

	nvm install 10

	if [ ! "$ARCHITECTURE" == "aarch64" ]
	then
		npm install --unsafe-perm --only=production -g @celo/celocli@1.0.3
	fi

	nvm cache clear
	npm cache clean --force
	rm -rf /root/.cache
EOF

# ./install | create hummingbot environment
RUN <<-EOF
	MINICONDA_ENVIRONMENT=$(head -1 /root/setup/environment.yml | cut -d' ' -f2)
	if [ -z "$MINICONDA_ENVIRONMENT" ]
	then
		echo "The MINICONDA_ENVIRONMENT environment variable could not be defined."
		exit 1
	fi
	echo "export MINICONDA_ENVIRONMENT=$MINICONDA_ENVIRONMENT" >> /root/.bashrc

	/root/miniconda3/bin/conda env create -f /root/setup/environment.yml
	/root/miniconda3/bin/conda clean -tipy
	rm -rf /root/.cache
EOF

SHELL [ "/bin/bash", "-lc" ]
# activate hummingbot env when entering the CT
# ./compile + cleanup build folder
RUN <<-EOF
	echo "source /root/miniconda3/etc/profile.d/conda.sh && conda activate $MINICONDA_ENVIRONMENT" >> /root/.bashrc
	/root/miniconda3/envs/$MINICONDA_ENVIRONMENT/bin/python3 setup.py build_ext --inplace -j 8
	rm -rf /root/build/
	find . -type f -name "*.cpp" -delete
EOF

RUN <<-EOF
	mkdir -p \
	/root/certs \
	/root/conf/connectors \
	/root/conf/strategies \
	/root/conf/scripts \
	/root/logs \
	/root/data \
	/root/scripts \
	/root/pmm_scripts \
	/var/lib/gateway
EOF

RUN <<-EOF
	apt autoremove -y

	apt clean autoclean

	rm -rf \
		/var/lib/apt/lists/* \
		/etc/apt/sources.list \
		/etc/apt/sources.list.d/*
EOF

CMD /root/miniconda3/envs/hummingbot/bin/python3 /root/bin/hummingbot_quickstart.py
