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
		postgresql-server-dev-all \
		tmux

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

	# Funttastic Client server environment variables

	if [ -z "$FUN_CLIENT_PORT" ]
	then
		echo 'export FUN_CLIENT_PORT=50001' >> ~/.bashrc
	else
		echo "export FUN_CLIENT_PORT=$FUN_CLIENT_PORT" >> ~/.bashrc
	fi

	# HB Gateway environment variables

	if [ -z "$HB_GATEWAY_PORT" ]
	then
		echo 'export HB_GATEWAY_PORT=15888' >> ~/.bashrc
	else
		echo "export HB_GATEWAY_PORT=$HB_GATEWAY_PORT" >> ~/.bashrc
	fi

	# HB Client environment variables

	# FileBrowser environment variables

	if [ -z "$FILEBROWSER_PORT" ]
	then
		echo 'export FILEBROWSER_PORT=50002' >> ~/.bashrc
	else
		echo "export FILEBROWSER_PORT=$FILEBROWSER_PORT" >> ~/.bashrc
	fi
	echo 'export VITE_FILEBROWSER_PORT=$FILEBROWSER_PORT' >> ~/.bashrc

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
  local session="fun-frontend"

  if [ "$(is_session_running "$session")" = "FALSE" ]; then
		tmux new-session -d -s "$session"

		tmux send-keys -t "$session" "cd /root/funttastic/frontend" C-m
		tmux send-keys -t "$session" "APP=fun-frontend yarn start --host" C-m
	fi
}

start_filebrowser() {
  local session="filebrowser"

  if [ "$(is_session_running "$session")" = "FALSE" ]; then
		tmux new-session -d -s "$session"

		tmux send-keys -t "$session" "cd /root/filebrowser" C-m
		tmux send-keys -t "$session" "APP=filebrowser filebrowser --address=0.0.0.0 -p \$FILEBROWSER_PORT -r ../shared" C-m
	fi
}

start_fun_client() {
  local password="$1"
  local session="fun-client"

  if [ "$(is_session_running "$session")" = "FALSE" ]; then
		tmux new-session -d -s "$session"

		tmux set-environment -t "$session" PASSWORD "$password"
		tmux send-keys -t "$session" "export PASSWORD=$(tmux show-environment PASSWORD | cut -d= -f2)" C-m
		tmux send-keys -t "$session" "conda activate funttastic" C-m
		tmux send-keys -t "$session" "cd /root/funttastic/client" C-m
		tmux send-keys -t "$session" "APP=fun-client python app.py" C-m
		tmux set-environment -t "$session" -u PASSWORD
	fi
}

start_hb_gateway() {
  local password="$1"
  local session="hb-gateway"

  if [ "$(is_session_running "$session")" = "FALSE" ]; then
		tmux new-session -d -s "$session"

		tmux set-environment -t "$session" GATEWAY_PASSPHRASE "$password"
		tmux send-keys -t "$session" "export GATEWAY_PASSPHRASE=$(tmux show-environment GATEWAY_PASSPHRASE | cut -d= -f2)" C-m
		tmux send-keys -t "$session" "cd /root/hummingbot/gateway" C-m
		tmux send-keys -t "$session" "APP=hb-gateway yarn start" C-m
		tmux set-environment -t "$session" -u GATEWAY_PASSPHRASE
	fi
}

start_hb_client() {
	local session="hb-client"

	if [ "$(is_session_running "$session")" = "FALSE" ]; then
		tmux new-session -d -s "$session"

		tmux send-keys -t "$session" "conda activate hummingbot" C-m
		tmux send-keys -t "$session" "cd /root/hummingbot/client" C-m
		tmux send-keys -t "$session" "APP=hb-client python bin/hummingbot_quickstart.py; exit" C-m
	fi
}

keep() {
	if [ "$(is_process_running "keep")" = "FALSE" ]; then
    APP=keep tail -f /dev/null
  fi
}

start_all() {
	local username="$1"
	local password="$2"

	start_fun_frontend
	start_filebrowser
	start_fun_client "$password"
	start_hb_gateway "$password"
	start_hb_client
}

start() {
	local credentials
	local username="${1:-$ADMIN_USERNAME}"
	local password="${1:-$ADMIN_PASSWORD}"

	args_to_check=("--start_all" "--start_fun_frontend" "--start_filebrowser" "--start_fun_client" "--start_hb_gateway" "--start_hb_client")

	for arg in "${args_to_check[@]}"; do
		if [[ "$username" == "$arg" ]]; then
			username=""
			break
		fi
	done

	for arg in "${args_to_check[@]}"; do
		if [[ "$password" == "$arg" ]]; then
			password=""
			break
		fi
	done

	source ~/.bashrc

	if [[ -n "$username" && -n "$password"  ]]; then
		credentials=$(authenticate "$username" "$password")
	elif [ -f "/root/.temp_credentials" ]; then
		# This condition is only for the first start.

		username=$(grep "username" "/root/.temp_credentials" | cut -d'=' -f2)
		password=$(grep "password" "/root/.temp_credentials" | cut -d'=' -f2)

		credentials=$(authenticate "$username" "$password")

		if [ -n "$credentials" ]; then
			rm -f /root/.temp_credentials
		fi
	else
		credentials=$(authenticate)
	fi

	if echo "$credentials" | grep -iq "error"; then
		echo "$credentials" >&2
		return 1
	else
		username=$(extract_credentials "username" "$credentials")
		password=$(extract_credentials "password" "$credentials")
	fi

	if [[ "$*" != *"--start_fun_frontend"* && \
				"$*" != *"--start_filebrowser"* && \
				"$*" != *"--start_fun_client"* && \
				"$*" != *"--start_hb_gateway"* && \
				"$*" != *"--start_hb_client"* ]]
	then
		start_all "$username" "$password"
		return
	fi

	while [[ $# -gt 0 ]]; do
		case "$1" in
			--start_all)
				start_all "$username" "$password"
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

is_session_running() {
	local session="$1"

	tmux has-session -t "$session" 2>/dev/null

	if [ $? -eq 0 ]; then
		echo "TRUE"
	else
		echo "FALSE"
	fi
}

is_process_running() {
	local app="$1"
	local target_pids parent_pids child_pids

	target_pids=$(grep -l "\bAPP=$app\b" /proc/*/environ | cut -d/ -f3 || true)

	if [ ! -z "$target_pids" ]; then
		echo "TRUE"
	else
		echo "FALSE"
	fi
}

kill_processes_and_subprocesses() {
	local app="$1"
	local target_pids parent_pids child_pids

	target_pids=$(grep -l "\bAPP=$app\b" /proc/*/environ | cut -d/ -f3 || true)

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
  tmux kill-session -t "fun-frontend"
}

stop_filebrowser() {
  tmux kill-session -t "filebrowser"
}

stop_fun_client() {
  tmux kill-session -t "fun-client"
}

stop_hb_gateway() {
  tmux kill-session -t "hb-gateway"
}

stop_hb_client() {
  tmux kill-session -t "hb-client"
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
	local fun_frontend_status=$(tmux has-session -t "fun-frontend" 2>/dev/null && echo "running" || echo "stopped")
	local filebrowser_status=$(tmux has-session -t "filebrowser" 2>/dev/null && echo "running" || echo "stopped")
	local fun_client_status=$(tmux has-session -t "fun-client" 2>/dev/null && echo "running" || echo "stopped")
	local hb_client_status=$(tmux has-session -t "hb-client" 2>/dev/null && echo "running" || echo "stopped")
	local hb_gateway_status=$(tmux has-session -t "hb-gateway" 2>/dev/null && echo "running" || echo "stopped")

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
	local message=$1

#	local hash_value=$(echo -n "$message" | openssl dgst -sha256)
	local hash_value=$(echo -n "$message" | sha256sum | awk '{print $1}')

	echo "$hash_value"
}

escape_string() {
	local string=$1
	local escaped_string=""
#	local ord
	local symbols='$#&|;()<>*!?[]\/\"\`'

	for ((i=0; i<${#string}; i++)); do
		character="${string:i:1}"
		if [[ $symbols =~ "$character" ]]; then
#			ord=$(printf '%d' "'$character")
#			escaped_string+="\\$ord"
			escaped_string+="\\$character"
		else
			escaped_string+="$character"
		fi
	done

	echo "$escaped_string"
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

get_credentials() {
	local username="$1"
	local password="$2"
	local credentials_json

	if [ -z "$username" ]; then
		read -rp "Username: " username
		username=$(escape_string "$username")
	fi

	if [ -z "$password" ]; then
		read -rs -p "Password: " password
		password=$(escape_string "$password")
	fi

	credentials_json="{ \"username\": \"$username\", \"password\": \"$password\" }"

	echo "$credentials_json"
}

authenticate() {
	local username="$1"
	local password="$2"

	if [ ! -f "/root/.ssh/id_rsa" ] || { [[ -n "$username" ]] && [[ -n "$password" ]]; }; then
		if [ -n "$NON_ENCRYPTED_CREDENTIALS_SHA256SUM" ]; then
			local non_encrypted_informed_credentials_json
			local non_encrypted_informed_credentials_json_sha256sum

			if [[ -n "$username" && -n "$password"  ]]; then
				non_encrypted_informed_credentials_json=$(get_credentials "$username" "$password")
			else
				non_encrypted_informed_credentials_json=$(get_credentials)
			fi

			non_encrypted_informed_credentials_json_sha256sum=$(generate_sha256sum "$non_encrypted_informed_credentials_json")

			if [ "$non_encrypted_informed_credentials_json_sha256sum" == "$NON_ENCRYPTED_CREDENTIALS_SHA256SUM" ]; then
				echo $non_encrypted_informed_credentials_json
			else
				>&2 echo "Error: Authentication failed. Invalid username or password."
				return 1
			fi
		else
			>&2 echo "Error: Authentication failed. No stored credentials hash found."
			return 1
		fi
	else
		if [ -n "$ENCRYPTED_CREDENTIALS" ]; then
			local decrypted_stored_credentials_json

			decrypted_stored_credentials_json=$(decrypt_message "$ENCRYPTED_CREDENTIALS")

			echo $decrypted_stored_credentials_json
		else
			>&2 echo "Error: Authentication failed. No stored encrypted credentials found."
			return 1
		fi
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

	# HB Client
	conda activate hummingbot
	python funttastic/client/resources/scripts/generate_hb_client_password_verification_file.py -p "$ADMIN_PASSWORD" -d hummingbot/client/conf

	# Fun Client
	conda activate funttastic
	python funttastic/client/resources/scripts/generate_ssl_certificates.py --passphrase $ADMIN_PASSWORD --cert-path funttastic/client/resources/certificates

	# Fun Frontend

	# Filebrowser
	cd filebrowser
	filebrowser users add $ADMIN_USERNAME $ADMIN_PASSWORD --perm.admin
#	filebrowser users update $ADMIN_USERNAME --commands="ls,git,tree,curl,rm,mkdir,pwd,cp,mv,cat,less,find,touch,echo,chmod,chown,df,du,ps,kill"

	mkdir -p /root/.ssh
	chmod 0700 /root/.ssh
	cd /root/.ssh/

	# Generate a new pair of RSA keys using OpenSSL
	openssl genpkey -algorithm RSA -out id_rsa_openssl.pem -pkeyopt rsa_keygen_bits:4096 > /dev/null 2>&1
	openssl rsa -pubout -in id_rsa_openssl.pem -out id_rsa_openssl.pub.pem > /dev/null 2>&1

	# Convert the OpenSSL keys to the SSH format (PEM)
	openssl rsa -in id_rsa_openssl.pem -out id_rsa > /dev/null 2>&1
	ssh-keygen -f id_rsa_openssl.pub.pem -i -mPKCS8 > id_rsa.pub

	# Restricting permissions
	chmod 600 id_rsa_openssl.pem
	chmod 600 id_rsa_openssl.pub.pem
	chmod 600 id_rsa
	chmod 600 id_rsa.pub

	escaped_admin_username=$(escape_string "${ADMIN_USERNAME}")
	escaped_admin_password=$(escape_string "${ADMIN_PASSWORD}")

	credentials_json="{ \"username\": \"$escaped_admin_username\", \"password\": \"$escaped_admin_password\" }"

	ENCRYPTED_CREDENTIALS_BASE64=$(encrypt_message "$credentials_json")

	# Necessary because the cipher generated with OpenSSL is not always the same
	NON_ENCRYPTED_CREDENTIALS_JSON_SHA256SUM=$(generate_sha256sum "$credentials_json")

	echo "# Credentials Section - Begin" >> /root/.bashrc
	echo "export ENCRYPTED_CREDENTIALS=\"$ENCRYPTED_CREDENTIALS_BASE64\"" >> /root/.bashrc
	echo "export NON_ENCRYPTED_CREDENTIALS_SHA256SUM=\"$NON_ENCRYPTED_CREDENTIALS_JSON_SHA256SUM\"" >> /root/.bashrc
	echo "# Credentials Section - End" >> /root/.bashrc

	# Necessary because the CMD instruction does not work with variables of type ARG, only of type ENV
	# We cannot convert the ADMIN_USERNAME and ADMIN_PASSWORD variables to ENV for security reasons
	echo "username=$ADMIN_USERNAME" > /root/.temp_credentials
	echo "password=$ADMIN_PASSWORD" >> /root/.temp_credentials

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

CMD ["/bin/bash", "-c", "source /root/.bashrc && keep"]
