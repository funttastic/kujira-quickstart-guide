FROM ubuntu:latest

ARG DEBIAN_FRONTEND=noninteractive
ARG TZ="Etc/GMT"
ARG LOCK_APT=${LOCK_AP:-"TRUE"}

ARG RANDOM_PASSPHRASE
ARG SSH_DEPLOY_PUBLIC_KEY
ARG SSH_DEPLOY_PRIVATE_KEY

ARG FUN_CLIENT_COMMAND=$FUN_CLIENT_COMMAND
ARG FUN_CLIENT_REPOSITORY_URL="${FUN_CLIENT_REPOSITORY_URL:-https://github.com/funttastic/fun-hb-client.git}"
ARG FUN_CLIENT_REPOSITORY_BRANCH="${FUN_CLIENT_REPOSITORY_BRANCH:-community}"
ENV FUN_CLIENT_PORT=${FUN_CLIENT_PORT:-50001}

ARG HB_GATEWAY_COMMAND=$HB_GATEWAY_COMMAND
ARG HB_GATEWAY_REPOSITORY_URL=${HB_GATEWAY_REPOSITORY_URL:-https://github.com/Team-Kujira/gateway.git}
ARG HB_GATEWAY_REPOSITORY_BRANCH=${HB_GATEWAY_REPOSITORY_BRANCH:-community}
ENV HB_GATEWAY_PORT=${HB_GATEWAY_PORT:-15888}
ARG HB_GATEWAY_PASSPHRASE
ENV GATEWAY_PORT=$HB_GATEWAY_PORT
ENV GATEWAY_PASSPHRASE=$HB_GATEWAY_PASSPHRASE

ARG HB_CLIENT_COMMAND=$HB_CLIENT_COMMAND
ARG HB_CLIENT_REPOSITORY_URL=${HB_CLIENT_REPOSITORY_URL:-https://github.com/Team-Kujira/hummingbot.git}
ARG HB_CLIENT_REPOSITORY_BRANCH=${HB_CLIENT_REPOSITORY_BRANCH:-community}

ARG FILEBROWSER_COMMAND=$FILEBROWSER_COMMAND
ENV FILEBROWSER_PORT=${FILEBROWSER_PORT:-50000}

EXPOSE $FUN_CLIENT_PORT
#EXPOSE $HB_GATEWAY_PORT

WORKDIR /root

RUN :> /root/.bashrc

RUN rm /usr/bin/sh && ln -s /bin/bash /usr/bin/sh

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

RUN <<-EOF
	set -e
	set +x

	if [[ "$SSH_DEPLOY_PUBLIC_KEY" && "$SSH_DEPLOY_PRIVATE_KEY" ]]; then \
	  set -ex

    mkdir -p /root/.ssh
    chmod 0700 /root/.ssh
    ssh-keyscan github.com > /root/.ssh/known_hosts

		echo "$SSH_DEPLOY_PUBLIC_KEY" > /root/.ssh/id_rsa.pub

		set +x
		echo "$SSH_DEPLOY_PRIVATE_KEY" > /root/.ssh/id_rsa

		set -ex
    chmod 600 /root/.ssh/id_rsa
    chmod 600 /root/.ssh/id_rsa.pub
	fi

	set +ex
EOF

RUN <<-EOF
	set -ex

	unlink /usr/bin/pip
	ln -s /usr/bin/python3 /usr/bin/python
	ln -s /usr/bin/pip3 /usr/bin/pip

	set +ex
EOF

RUN <<-EOF
	set -ex

	curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash
	rm -f get.sh

	set +ex
EOF

RUN <<-EOF
	set -ex

	source /root/.bashrc

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

	echo 'export PATH=/root/miniconda3/bin:$PATH' >> /root/.bashrc
	source /root/.bashrc

	conda update -n base -c conda-forge conda -y
	conda clean -tipy

	echo "export MINICONDA_VERSION=$MINICONDA_VERSION" >> /root/.bashrc
	echo "export MINICONDA_URL=$MINICONDA_URL" >> /root/.bashrc

	conda init --all

	set +ex
EOF

RUN <<-EOF
	set -ex

	source /root/.bashrc

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

	source /root/.bashrc

	mkdir -p funttastic/client
	cd funttastic/client

	git clone -b $FUN_CLIENT_REPOSITORY_BRANCH $FUN_CLIENT_REPOSITORY_URL .

	conda env create -f environment.yml

	conda activate funttastic

	mkdir -p resources/certificates
	cp resources/configuration/production.example.yml resources/configuration/production.yml
	cp -a resources/strategies/templates/. resources/strategies

	set +ex
EOF

RUN <<-EOF
	set -ex

	source /root/.bashrc

	mkdir -p hummingbot/gateway
	cd hummingbot/gateway

	git clone -b $HB_GATEWAY_REPOSITORY_BRANCH $HB_GATEWAY_REPOSITORY_URL .

	mkdir -p \
		certs \
		db \
		conf \
		logs \
		/var/lib

	cp -a src/templates/. conf

	yarn
	yarn prebuild
	yarn build

	set +ex
EOF

RUN <<-EOF
	set -ex

	source /root/.bashrc

	mkdir -p hummingbot/client
	cd hummingbot/client

	git clone -b $HB_CLIENT_REPOSITORY_BRANCH $HB_CLIENT_REPOSITORY_URL .

	MINICONDA_ENVIRONMENT=$(head -1 setup/environment.yml | cut -d' ' -f2)
	if [ -z "$MINICONDA_ENVIRONMENT" ]
	then
		echo "The MINICONDA_ENVIRONMENT environment variable could not be defined."
		exit 1
	fi
	echo "export MINICONDA_ENVIRONMENT=$MINICONDA_ENVIRONMENT" >> /root/.bashrc

	conda env create -f setup/environment.yml
	conda clean -tipy
	rm -rf /root/.cache

	echo "source /root/miniconda3/etc/profile.d/conda.sh && conda activate $MINICONDA_ENVIRONMENT" >> /root/.bashrc
	/root/miniconda3/envs/$MINICONDA_ENVIRONMENT/bin/python3 setup.py build_ext --inplace -j 8
	rm -rf build/
	find . -type f -name "*.cpp" -delete

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

RUN <<-EOF
	set -ex

	echo "export GATEWAY_PASSPHRASE=$HB_GATEWAY_PASSPHRASE" >> /root/.bashrc
	rm -rf /root/temp

	source /root/.bashrc

	conda activate funttastic

	python funttastic/client/resources/scripts/generate_ssl_certificates.py --passphrase $HB_GATEWAY_PASSPHRASE --cert-path funttastic/client/resources/certificates

	ln -rfs funttastic/client/resources/certificates/* hummingbot/gateway/certs
	ln -rfs funttastic/client/resources/certificates/* hummingbot/client/certs

	sed -i "s/<password>/"$HB_GATEWAY_PASSPHRASE"/g" funttastic/client/resources/configuration/production.yml
	sed -i -e '/logging:/,/use_telegram: true/ s/use_telegram: true/use_telegram: false/' -e '/telegram:/,/enabled: true/ s/enabled: true/enabled: false/' -e '/telegram:/,/listen_commands: true/ s/listen_commands: true/listen_commands: false/' funttastic/client/resources/configuration/production.yml
	sed -i -e '/telegram:/,/enabled: true/ s/enabled: true/enabled: false/' -e '/telegram:/,/listen_commands: true/ s/listen_commands: true/listen_commands: false/' funttastic/client/resources/configuration/common.yml

	if [ "$HB_GATEWAY_PASSPHRASE" == "$RANDOM_PASSPHRASE" ]
	then
	  mkdir -p shared/temporary
		echo $RANDOM_PASSPHRASE > shared/temporary/random_passphrase.txt
	fi

	set +ex
EOF

RUN <<-EOF
	set -ex

	mkdir -p \
		shared/common \
		shared/funttastic/client \
		shared/hummingot/client \
		shared/hummingbot/gateway

	mv funttastic/client/resources/certificates shared/common/
	rm -rf hummingbot/client/certs
	rm -rf hummingbot/gateway/certs
	ln -s shared/common/certificates funttastic/client/resources/certificates
	ln -s shared/common/certificates hummingbot/client/certs
	ln -s shared/common/certificates hummingbot/gateway/certs

	mv funttastic/client/resources shared/funttastic/client/
	ln -s shared/funttastic/client/resources funttastic/client/resources

  mv hummingbot/gateway/db shared/hummingbot/gateway/
  mv hummingbot/gateway/conf shared/hummingbot/gateway/
  mv hummingbot/gateway/logs shared/hummingbot/gateway/
  ln -s shared/hummingbot/gateway/db humminbot/gateway/db
  ln -s shared/hummingbot/gateway/conf humminbot/gateway/conf
  ln -s shared/hummingbot/gateway/logs humminbot/gateway/logs

  mv hummingbot/client/conf shared/hummingbot/client/
  mv hummingbot/client/logs shared/hummingbot/client/
  mv hummingbot/client/data shared/hummingbot/client/
  mv hummingbot/client/scripts shared/hummingbot/client/
  mv hummingbot/client/pmm_scripts shared/hummingbot/client/
  ln -s shared/hummingbot/client/conf hummingbot/client/conf
  ln -s shared/hummingbot/client/logs hummingbot/client/logs
  ln -s shared/hummingbot/client/data hummingbot/client/data
  ln -s shared/hummingbot/client/scripts hummingbot/client/scripts
  ln -s shared/hummingbot/client/pmm_scripts hummingbot/client/pmm_scripts

	set +ex
EOF

RUN <<-EOF
	set -ex

	filebrowser -p $FILEBROWSER_PORT -r /root/shared

	set +ex
EOF

RUN <<-EOF
	set -ex

	if [ "$LOCK_APT" == "TRUE" ]
	then
		apt autoremove -y

		apt clean autoclean

		rm -rf \
			/var/lib/apt/lists/* \
			/etc/apt/sources.list \
			/etc/apt/sources.list.d/* \
			/tmp/* \
			/var/tmp/*
	fi

	set +ex
EOF

CMD ["/bin/bash", "-c", "$FUN_HB_CLIENT_COMMAND; $HB_GATEWAY_COMMAND; $HB_CLIENT_COMMAND; $FILEBROWSER_COMMAND"]
