FROM ubuntu:latest

ARG DEBIAN_FRONTEND=noninteractive
ARG TZ="Etc/GMT"
ARG LOCK_APT=${LOCK_APT:-"TRUE"}

ARG ADMIN_USERNAME
ARG ADMIN_PASSWORD
ARG AUTO_SIGNIN

ARG FUN_FRONTEND_REPOSITORY_URL="${FUN_FRONTEND_REPOSITORY_URL:-https://github.com/funttastic/fun-hb-frontend.git}"
ARG FUN_FRONTEND_REPOSITORY_BRANCH="${FUN_FRONTEND_REPOSITORY_BRANCH:-development}"
ARG FUN_FRONTEND_COMMAND
ARG FUN_FRONTEND_PORT

ARG FUN_CLIENT_REPOSITORY_URL="${FUN_CLIENT_REPOSITORY_URL:-https://github.com/funttastic/fun-hb-client.git}"
ARG FUN_CLIENT_REPOSITORY_BRANCH="${FUN_CLIENT_REPOSITORY_BRANCH:-community}"
ARG FUN_CLIENT_COMMAND
ARG FUN_CLIENT_PORT

ARG HB_GATEWAY_REPOSITORY_URL=${HB_GATEWAY_REPOSITORY_URL:-https://github.com/Team-Kujira/gateway.git}
ARG HB_GATEWAY_REPOSITORY_BRANCH=${HB_GATEWAY_REPOSITORY_BRANCH:-community}
ARG HB_GATEWAY_COMMAND
ARG HB_GATEWAY_PORT
ARG HB_GATEWAY_PASSPHRASE=${ADMIN_PASSWORD}
ARG GATEWAY_PASSPHRASE=$HB_GATEWAY_PASSPHRASE

ARG HB_CLIENT_REPOSITORY_URL=${HB_CLIENT_REPOSITORY_URL:-https://github.com/Team-Kujira/hummingbot.git}
ARG HB_CLIENT_REPOSITORY_BRANCH=${HB_CLIENT_REPOSITORY_BRANCH:-community}
ARG HB_CLIENT_COMMAND

ARG FILEBROWSER_COMMAND
ARG FILEBROWSER_PORT

EXPOSE $FUN_FRONTEND_PORT
EXPOSE $FILEBROWSER_PORT

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
		less \
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
	set -ex

	echo -e "\n" >> ~/.bashrc

	# Funttastic Client Frontend environment variables

	if [ -z "$FRONTEND_PORT" ]
	then
		echo 'export FRONTEND_PORT=50000' >> ~/.bashrc
	else
		echo "export FRONTEND_PORT=$FRONTEND_PORT" >> ~/.bashrc
	fi

	if [ -z "$FUN_FRONTEND_COMMAND" ]
	then
		echo "export FUN_FRONTEND_COMMAND=\"cd /root/funttastic/frontend && yarn start --host > /dev/null 2>&1 &\"" >> ~/.bashrc
	else
		echo "export FUN_FRONTEND_COMMAND=\"$FUN_FRONTEND_COMMAND\"" >> ~/.bashrc
	fi

	# Funttastic Client server environment variables

	if [ -z "$FUN_CLIENT_PORT" ]
	then
		echo 'export FUN_CLIENT_PORT=50001' >> ~/.bashrc
	else
		echo "export FUN_CLIENT_PORT=$FUN_CLIENT_PORT" >> ~/.bashrc
	fi

	if [ -z "$FUN_CLIENT_COMMAND" ]
	then
		echo "export FUN_CLIENT_COMMAND=\"conda activate funttastic && cd /root/funttastic/client && python app.py > /dev/null 2>&1 &\"" >> ~/.bashrc
	else
		echo "export FUN_CLIENT_COMMAND=\"$FUN_CLIENT_COMMAND\"" >> ~/.bashrc
	fi

	# HB Gateway environment variables

	if [ -z "$HB_GATEWAY_PORT" ]
	then
		echo 'export HB_GATEWAY_PORT=15888' >> ~/.bashrc
	else
		echo "export HB_GATEWAY_PORT=$HB_GATEWAY_PORT" >> ~/.bashrc
	fi

	if [ -z "$HB_GATEWAY_COMMAND" ]
	then
		echo "export HB_GATEWAY_COMMAND=\"cd /root/hummingbot/gateway && yarn start > /dev/null 2>&1 &\"" >> ~/.bashrc
	else
		echo "export HB_GATEWAY_COMMAND=\"$HB_GATEWAY_COMMAND\"" >> ~/.bashrc
	fi

	# HB Client environment variables

	if [ -z "$HB_CLIENT_COMMAND" ]
	then
		echo "export HB_CLIENT_COMMAND=\"conda activate hummingbot && cd /root/hummingbot/client && python bin/hummingbot_quickstart.py 2>> ./logs/errors.log\"" >> ~/.bashrc
	else
		echo "export HB_CLIENT_COMMAND=\"$HB_CLIENT_COMMAND\"" >> ~/.bashrc
	fi

	# FileBrowser environment variables

	if [ -z "$FILEBROWSER_PORT" ]
	then
		echo 'export FILEBROWSER_PORT=50002' >> ~/.bashrc
	else
		echo "export FILEBROWSER_PORT=$FILEBROWSER_PORT" >> ~/.bashrc
	fi
	echo 'export VITE_FILEBROWSER_PORT=$FILEBROWSER_PORT' >> ~/.bashrc

	if [ -z "$FILEBROWSER_COMMAND" ]
	then
		echo "export FILEBROWSER_COMMAND=\"cd /root/filebrowser && filebrowser --address=0.0.0.0 -p \$FILEBROWSER_PORT -r ../shared > /dev/null 2>&1 &\"" >> ~/.bashrc
	else
		echo "export FILEBROWSER_COMMAND=\"$FILEBROWSER_COMMAND\"" >> ~/.bashrc
	fi

	echo -e "\n" >> ~/.bashrc

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

	nvm install --lts
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

	mkdir -p funttastic/frontend
	cd funttastic/frontend

	git clone -b $FUN_FRONTEND_REPOSITORY_BRANCH $FUN_FRONTEND_REPOSITORY_URL .

	yarn install

	set +ex
EOF

RUN <<-EOF
	set -ex

	curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash
	rm -f get.sh

	mkdir -p filebrowser/branding/img
	cd filebrowser

	filebrowser config init
	filebrowser config set --branding.name "Funttastic"
	filebrowser config set --branding.theme "dark"
	filebrowser config set --branding.files /root/filebrowser/branding
	filebrowser config set --port $FILEBROWSER_PORT
	filebrowser config set --baseurl /

		cp /root/funttastic/frontend/resources/assets/funttastic/logo/logo.svg branding/img/logo.svg

	cat <<'CSS' > branding/custom.css
html {
		scrollbar-width: none;
}

header {
		padding: 0.5em 0 0.5em 0;
}

header img {
		display: none;
}
CSS

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

	rm -rf /root/temp

	source /root/.bashrc

	conda activate funttastic

	ln -rfs funttastic/client/resources/certificates/* hummingbot/gateway/certs
	ln -rfs funttastic/client/resources/certificates/* hummingbot/client/certs

	sed -i -e "/server:/,/port: [0-9]*/ s/port: [0-9]*/port: $FUN_CLIENT_PORT/" funttastic/client/resources/configuration/production.yml
	sed -i -e '/logging:/,/use_telegram:/ s/use_telegram:.*/use_telegram: false/' -e '/telegram:/,/enabled:/ s/enabled:.*/enabled: false/' -e '/telegram:/,/listen_commands:/ s/listen_commands:.*/listen_commands: false/' funttastic/client/resources/configuration/production.yml
	sed -i -e '/telegram:/,/enabled:/ s/enabled:.*/enabled: false/' -e '/telegram:/,/listen_commands:/ s/listen_commands:.*/listen_commands: false/' funttastic/client/resources/configuration/common.yml

	set +ex
EOF

RUN <<-EOF
set -ex

mkdir -p shared/scripts

cat <<'SCRIPT' > shared/scripts/functions.sh
#!/bin/bash

start_fun_frontend() {
	eval $FUN_FRONTEND_COMMAND
}

start_filebrowser() {
	eval $FILEBROWSER_COMMAND
}

start_fun_client() {
	eval $FUN_CLIENT_COMMAND
}

start_hb_gateway() {
	local password="$1"

	export GATEWAY_PASSPHRASE="$password"

	eval $HB_GATEWAY_COMMAND

	unset GATEWAY_PASSPHRASE
}

start_hb_client() {
	eval $HB_CLIENT_COMMAND
}

keep() {
	tail -f /dev/null
}

start_all() {
	local username="$1"
	local password="$2"

	start_fun_frontend
	start_filebrowser
	start_fun_client
	start_hb_gateway "$password"
	keep
}

start() {
	local credentials
	local username
	local password

	source ~/.bashrc

	credentials=$(authenticate)

	if echo "$credentials" | grep -iq "error"; then
		echo "$credentials" >&2
		return 1
	else
		username=$(extract_credentials "username" "$credentials")
		password=$(extract_credentials "password" "$credentials")
	fi

	if [[ $# -eq 0 ]]; then
		start_all
		return
	fi

	while [[ $# -gt 0 ]]; do
		case "$1" in
			--start_all)
				start_all
				return
				;;
			--start_fun_frontend)
				start_fun_frontend
				return
				;;
			--start_filebrowser)
				start_filebrowser
				return
				;;
			--start_fun_client)
				start_fun_client
				return
				;;
			--start_hb_gateway)
				start_hb_gateway "$password"
				return
				;;
			--start_hb_client)
				start_hb_client
				return
				;;
			*)
		esac
		shift
	done
}

kill_processes_and_subprocesses() {
	local search_pattern="$1"
	local target_pids parent_pids child_pids

	target_pids=$(pgrep -f "$search_pattern" || true)

	if [ ! -z "$target_pids" ]; then
		parent_pids=$(echo "$target_pids" | grep -o -E '([0-9]+)' | tr "\n" " ")

		for parent_pid in $parent_pids; do
			child_pids=$(pstree -p $parent_pid | grep -o -E '([0-9]+)' | tr "\n" " ")

			kill -9 $parent_pid 2>/dev/null || true

			for child_pid in $child_pids; do
				kill -9 $child_pid 2>/dev/null || true
			done
		done
	fi
}

stop_fun_frontend() {
	kill_processes_and_subprocesses "start_fun_frontend"
}

stop_filebrowser() {
	kill_processes_and_subprocesses "start_filebrowser"
}

stop_fun_client() {
	kill_processes_and_subprocesses "start_fun_client"
}

stop_hb_gateway() {
	kill_processes_and_subprocesses "start_hb_gateway"
}

stop_hb_client() {
	kill_processes_and_subprocesses "start_hb_client"
}

stop_all() {
	stop_fun_frontend
	stop_filebrowser
	stop_fun_client
	stop_hb_gateway
	stop_hb_client
}

stop() {
	source ~/.bashrc

	if [[ $# -eq 0 ]]; then
		stop_all
		return
	fi

	while [[ $# -gt 0 ]]; do
		case "$1" in
			--stop_all)
				stop_all
				return
				;;
			--stop_fun_frontend)
				stop_fun_frontend
				return
				;;
			--stop_filebrowser)
				stop_filebrowser
				return
				;;
			--stop_fun_client)
				stop_fun_client
				return
				;;
			--stop_hb_gateway)
				stop_hb_gateway
				return
				;;
			--stop_hb_client)
				stop_hb_client
				return
				;;
			*)
		esac
		shift
	done
}

status() {
	local fun_frontend_status=$(pgrep -f 'fun.*frontend.*vite' >/dev/null && echo 'running' || echo 'stopped')
	local filebrowser_status=$(pgrep -f 'filebrowser.*' >/dev/null && echo 'running' || echo 'stopped')
	local fun_client_status=$(pgrep -f 'python.*app.py' >/dev/null && echo 'running' || echo 'stopped')
	local hb_client_status=$(pgrep -f 'python.*hummingbot_quickstart.py' >/dev/null && echo 'running' || echo 'stopped')
	local hb_gateway_status=$(pgrep -f 'node.*yarn.*start' >/dev/null && echo 'running' || echo 'stopped')

	output=$(cat << OUTPUT
{
	"fun-frontend": "$fun_frontend_status",
	"filebrowser": "$filebrowser_status",
	"fun-client": "$fun_client_status",
	"hb-client": "$hb_client_status",
	"hb-gateway": "$hb_gateway_status"
}
OUTPUT
)

	echo $output
}

encrypt_message() {
	local message=$1

	# After encryption, it is converted to base64 format to avoid failures in transfers between variables and programs
	local encrypted_message_base64=$(echo "$message" | openssl pkeyutl -encrypt -pubin -inkey /root/.ssh/id_rsa_openssl.pub.pem -pkeyopt rsa_padding_mode:oaep | base64)

	echo "$encrypted_message_base64"
}

decrypt_message() {
	local encrypted_message_base64=$1

	# Decode the Base64 encrypted message and decrypt it directly
	local decrypted_message=$(echo "$encrypted_message_base64" | base64 --decode | openssl pkeyutl -decrypt -inkey /root/.ssh/id_rsa -pkeyopt rsa_padding_mode:oaep)

	echo "$decrypted_message"
}

generate_sha256sum() {
	local encrypted_message_base64=$1

	# Generate a SHA256 hash of the encrypted Base64 message
	local hash_value=$(echo -n "$encrypted_message_base64" | sha256sum | awk '{print $1}')

	echo "$hash_value"
}

escape_string() {
	local string=$1
	local escaped_string="${string//\"/\\\"}"

	echo "${escaped_string//[^a-zA-Z0-9 ,.\-_]/}"
}

extract_credentials() {
	local key=$1
	local json_string=$2
	local value

	if [ "$key" = "username" ]; then
		value=$(echo $json_string | sed -n 's/.*"username": "\([^"]*\)".*/\1/p')
	elif [ "$key" = "password" ]; then
		value=$(echo $json_string | sed -n 's/.*"password": "\([^"]*\)".*/\1/p')
	else
		value=""
	fi

	echo "$value"
}

#fix_credentials_exports() {
#	local encrypted_message_base64=$1
#	local encrypted_message_base64_sha256sum=$1
#
#	if [ -n "$encrypted_message_base64" ]; then
#		if grep -q "export ENCRYPTED_CREDENTIALS=" /root/.bashrc; then
#			if grep -q "export ENCRYPTED_CREDENTIALS=\"\"" /root/.bashrc; then
#				sed -i '/export ENCRYPTED_CREDENTIALS=""/c\export ENCRYPTED_CREDENTIALS="'$encrypted_message_base64'"' /root/.bashrc
#			fi
#		else
#			echo "export ENCRYPTED_CREDENTIALS=\"$encrypted_message_base64\"" >> /root/.bashrc
#		fi
#	fi
#
#	if [ -n "$encrypted_message_base64_sha256sum" ]; then
#		if grep -q "export ENCRYPTED_CREDENTIALS_SHA256SUM=" /root/.bashrc; then
#			if grep -q "export ENCRYPTED_CREDENTIALS_SHA256SUM=\"\"" /root/.bashrc; then
#				sed -i '/export ENCRYPTED_CREDENTIALS_SHA256SUM=""/c\export ENCRYPTED_CREDENTIALS_SHA256SUM="'$encrypted_message_base64_sha256sum'"' /root/.bashrc
#			fi
#		else
#			echo "export ENCRYPTED_CREDENTIALS_SHA256SUM=\"$encrypted_message_base64_sha256sum\"" >> /root/.bashrc
#		fi
#	fi
#}

authenticate() {
	local username="$1"
	local password="$2"

	get_credentials() {
		if [ -z "$username" ]; then
			echo
			read -p "Username: " username
		fi

		if [ -z "$password" ]; then
			read -s -p "Password: " password
		fi
	}

	if [ ! -f "/root/.ssh/id_rsa" ]; then
		get_credentials
	else
		if [ -n "$ENCRYPTED_CREDENTIALS" ]; then
			local decrypted_message
			json=$(decrypt_message "$ENCRYPTED_CREDENTIALS")

			username=$(extract_credentials "username" "$json")
			password=$(extract_credentials "password" "$json")
		else
			get_credentials
		fi
	fi

	local escaped_username
	local escaped_password
	local json
	local encrypted_message_base64
	local encrypted_message_base64_sha256sum

	escaped_username=$(escape_string "$username")
	escaped_password=$(escape_string "$password")

	json="{ \"username\": \"$escaped_username\", \"password\": \"$escaped_password\"}"

	encrypted_message_base64=$(encrypt_message "$json")
	encrypted_message_base64_sha256sum=$(generate_sha256sum "$encrypted_message")

	if [ -n "$ENCRYPTED_CREDENTIALS_SHA256SUM" ]; then
		if [ "$encrypted_message_base64_sha256sum" == "$ENCRYPTED_CREDENTIALS_SHA256SUM" ]; then
			echo $json
		else
			>&2 echo "Error: Authentication failed. Invalid username or password."
			return 1
		fi
	elif [ -n "$ENCRYPTED_CREDENTIALS" ]; then
		local stored_encrypted_message_base64_sha256sum
		stored_encrypted_message_base64_sha256sum=$(generate_sha256sum "$ENCRYPTED_CREDENTIALS")

		if [ "$encrypted_message_base64_sha256sum" == "$stored_encrypted_message_base64_sha256sum" ]; then
			echo $json
		else
			>&2 echo "Error: Authentication failed. Invalid username or password."
			return 1
		fi
	else
		>&2 echo "Error: Authentication failed. No stored credentials found."
		return 1
	fi
}

SCRIPT

chmod +x shared/scripts/functions.sh

cat <<'SCRIPT' > shared/scripts/initialize.sh
#!/bin/bash

source /root/shared/scripts/functions.sh

SCRIPT

echo "source /root/shared/scripts/initialize.sh" >> /root/.bashrc

source /root/.bashrc

set +ex
EOF

RUN <<-EOF
	set -e
	set +x

	source /root/.bashrc

	# HB Gateway
#  echo "export GATEWAY_PASSPHRASE=$HB_GATEWAY_PASSPHRASE" >> /root/.bashrc
#  source /root/.bashrc

	# HB Client
	conda activate hummingbot
	python funttastic/client/resources/scripts/generate_hb_client_password_verification_file.py -p "$ADMIN_PASSWORD" -d hummingbot/client/conf

	# Fun Client
	conda activate funttastic
	sed -i "s/<password>/"$ADMIN_PASSWORD"/g" funttastic/client/resources/configuration/production.yml
	python funttastic/client/resources/scripts/generate_ssl_certificates.py --passphrase $ADMIN_PASSWORD --cert-path funttastic/client/resources/certificates

	# Fun Frontend
	sed -i "s/password: '.*'/password: '$ADMIN_PASSWORD'/" funttastic/frontend/src/mock/data/authData.ts
	sed -i "s/accountUserName: '.*'/accountUserName: '$ADMIN_USERNAME'/" funttastic/frontend/src/mock/data/authData.ts

	# Filebrowser
	cd filebrowser
	filebrowser users add $ADMIN_USERNAME $ADMIN_PASSWORD --perm.admin
	filebrowser users update $ADMIN_USERNAME --commands="ls,git,tree,curl,rm,mkdir,pwd,cp,mv,cat,less,find,touch,echo,chmod,chown,df,du,ps,kill"

	mkdir -p /root/.ssh
	chmod 0700 /root/.ssh

	# Generate a new pair of RSA keys using OpenSSL
	openssl genpkey -algorithm RSA -out /root/.ssh/id_rsa_openssl.pem -pkeyopt rsa_keygen_bits:4096 > /dev/null 2>&1
	openssl rsa -pubout -in /root/.ssh/id_rsa_openssl.pem -out /root/.ssh/id_rsa_openssl.pub.pem > /dev/null 2>&1

	# Convert the OpenSSL keys to the SSH format (PEM)
	openssl rsa -in /root/.ssh/id_rsa_openssl.pem -out id_rsa > /dev/null 2>&1
	ssh-keygen -f /root/.ssh/id_rsa_openssl.pub.pem -i -mPKCS8 > id_rsa.pub

	# Restricting permissions
	chmod 600 /root/.ssh/id_rsa_openssl.pem
	chmod 600 /root/.ssh/id_rsa_openssl.pub.pem
	chmod 600 /root/.ssh/id_rsa
	chmod 600 /root/.ssh/id_rsa.pub

	local escaped_admin_username
	local escaped_admin_password

	escaped_admin_username=$(escape_string "${ADMIN_USERNAME}")
	escaped_admin_password=$(escape_string "${ADMIN_PASSWORD}")

	local ENCRYPTED_CREDENTIALS_BASE64
	ENCRYPTED_CREDENTIALS_BASE64=$(encrypt_message "{\"username\": \"$escaped_admin_username\", \"password\": \"$escaped_admin_password\"}")

	local ENCRYPTED_CREDENTIALS_BASE64_SHA256SUM
	ENCRYPTED_CREDENTIALS_BASE64_SHA256SUM=$(generate_sha256sum "$ENCRYPTED_CREDENTIALS_BASE64")

	echo "# Credentials Section - Start" >> /root/.bashrc
	echo "export ENCRYPTED_CREDENTIALS=\"$ENCRYPTED_CREDENTIALS_BASE64\"" >> /root/.bashrc
	echo "export ENCRYPTED_CREDENTIALS_SHA256SUM=\"$ENCRYPTED_CREDENTIALS_BASE64_SHA256SUM\"" >> /root/.bashrc
	echo "# Credentials Section - End" >> /root/.bashrc

	if [ ! "$AUTO_SIGNIN" == "TRUE" ]; then
		rm -f /root/.ssh/id_rsa
		rm -f /root/.ssh/id_rsa_openssl.pem
	fi

	set +ex
EOF

RUN <<-EOF
	set -ex

	mkdir -p \
		/root/shared/common \
		/root/shared/funttastic/client \
		/root/shared/hummingbot/client \
		/root/shared/hummingbot/gateway

	mv /root/funttastic/client/resources/certificates /root/shared/common/
	rm -rf /root/hummingbot/client/certs
	rm -rf /root/hummingbot/gateway/certs
	ln -s /root/shared/common/certificates /root/funttastic/client/resources/certificates
	ln -s /root/shared/common/certificates /root/hummingbot/client/certs
	ln -s /root/shared/common/certificates /root/hummingbot/gateway/certs

	mv /root/funttastic/client/resources /root/shared/funttastic/client/
	ln -s /root/shared/funttastic/client/resources /root/funttastic/client/resources

	mv /root/hummingbot/gateway/db /root/shared/hummingbot/gateway/
	mv /root/hummingbot/gateway/conf /root/shared/hummingbot/gateway/
	mv /root/hummingbot/gateway/logs /root/shared/hummingbot/gateway/
	ln -s /root/shared/hummingbot/gateway/db /root/hummingbot/gateway/db
	ln -s /root/shared/hummingbot/gateway/conf /root/hummingbot/gateway/conf
	ln -s /root/shared/hummingbot/gateway/logs /root/hummingbot/gateway/logs

	mv /root/hummingbot/client/conf /root/shared/hummingbot/client/
	mv /root/hummingbot/client/logs /root/shared/hummingbot/client/
	mv /root/hummingbot/client/data /root/shared/hummingbot/client/
	mv /root/hummingbot/client/scripts /root/shared/hummingbot/client/
	mv /root/hummingbot/client/pmm_scripts /root/shared/hummingbot/client/
	ln -s /root/shared/hummingbot/client/conf /root/hummingbot/client/conf
	ln -s /root/shared/hummingbot/client/logs /root/hummingbot/client/logs
	ln -s /root/shared/hummingbot/client/data /root/hummingbot/client/data
	ln -s /root/shared/hummingbot/client/scripts /root/hummingbot/client/scripts
	ln -s /root/shared/hummingbot/client/pmm_scripts /root/hummingbot/client/pmm_scripts

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

CMD ["/bin/bash", "-c", "source /root/.bashrc && start"]
