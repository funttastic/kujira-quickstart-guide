#!/bin/bash

fun_standalone_install() {
	set -ex

	local arguments=$*

	fun_export_variables $arguments

	fun_pre_install $arguments

	sudo -u user -i <<USER
		source /home/user/.bashrc
		source /tmp/standalone_install.sh
		fun_install $arguments
USER

	fun_post_install $arguments
}

fun_export_variables() {
	ADMIN_USERNAME=""
	ADMIN_PASSWORD=""
	ADMIN_EMAIL=""

	DOMAIN=""

	AUTO_SIGN_IN=""
	LOCK_APT=""

	FUN_FRONTEND_REPOSITORY_URL=""
	FUN_FRONTEND_REPOSITORY_BRANCH=""
	FUN_FRONTEND_COMMAND=""
	FUN_FRONTEND_PORT=""

	FUN_CLIENT_REPOSITORY_URL=""
	FUN_CLIENT_REPOSITORY_BRANCH=""
	FUN_CLIENT_COMMAND=""
	FUN_CLIENT_PORT=""

	HB_GATEWAY_REPOSITORY_URL=""
	HB_GATEWAY_REPOSITORY_BRANCH=""
	HB_GATEWAY_COMMAND=""
	HB_GATEWAY_PORT=""

	HB_CLIENT_REPOSITORY_URL=""
	HB_CLIENT_REPOSITORY_BRANCH=""
	HB_CLIENT_COMMAND=""

	FILEBROWSER_COMMAND=""
	FILEBROWSER_PORT=""

	USE_VALID_SSL_CERTIFICATES="FALSE"

	#--------------------------------------------------
	while [[ $# -gt 0 ]]; do
		case "$1" in
			--username=*)
				set +x
				export ADMIN_USERNAME="${1#*=}"
				set -x
				;;
			--password=*)
				set +x
				export ADMIN_PASSWORD="${1#*=}"
				export PASSWORD="${1#*=}"
				set -x
				;;
			--email=*)
				export ADMIN_EMAIL="${1#*=}"
				;;
			--user=*)
				export USER="${1#*=}"
				;;
			--domain=*)
				export DOMAIN="${1#*=}"
				;;
			--auto-sign-in=*)
				export AUTO_SIGN_IN="${1#*=}"
				;;
			--lock-apt=*)
				export LOCK_APT="${1#*=}"
				;;
			--fun-frontend-repository-url=*)
				export FUN_FRONTEND_REPOSITORY_URL="${1#*=}"
				;;
			--fun-frontend-repository-branch=*)
				export FUN_FRONTEND_REPOSITORY_BRANCH="${1#*=}"
				;;
			--fun-frontend-command=*)
				export FUN_FRONTEND_COMMAND="${1#*=}"
				;;
			--fun-frontend-port=*)
				export FUN_FRONTEND_PORT="${1#*=}"
				;;
			--fun-client-repository-url=*)
				export FUN_CLIENT_REPOSITORY_URL="${1#*=}"
				;;
			--fun-client-repository-branch=*)
				export FUN_CLIENT_REPOSITORY_BRANCH="${1#*=}"
				;;
			--fun-client-command=*)
				export FUN_CLIENT_COMMAND="${1#*=}"
				;;
			--fun-client-port=*)
				export FUN_CLIENT_PORT="${1#*=}"
				;;
			--hb-gateway-repository-url=*)
				export HB_GATEWAY_REPOSITORY_URL="${1#*=}"
				;;
			--hb-gateway-repository-branch=*)
				export HB_GATEWAY_REPOSITORY_BRANCH="${1#*=}"
				;;
			--hb-gateway-command=*)
				export HB_GATEWAY_COMMAND="${1#*=}"
				;;
			--hb-gateway-port=*)
				export HB_GATEWAY_PORT="${1#*=}"
				;;
			--hb-client-repository-url=*)
				export HB_CLIENT_REPOSITORY_URL="${1#*=}"
				;;
			--hb-client-repository-branch=*)
				export HB_CLIENT_REPOSITORY_BRANCH="${1#*=}"
				;;
			--hb-client-command=*)
				export HB_CLIENT_COMMAND="${1#*=}"
				;;
			--filebrowser-command=*)
				export FILEBROWSER_COMMAND="${1#*=}"
				;;
			--filebrowser-port=*)
				export FILEBROWSER_PORT="${1#*=}"
				;;
			*)
		esac
		shift
	done
	export USER=${ADMIN_USERNAME:-"user"}
}

fun_pre_install() {
	set -ex

	source /root/.bashrc

	chsh -s /bin/bash
	rm /usr/bin/sh
	ln -s /bin/bash /usr/bin/sh

	sed -i 's/^\([[:space:]]*\[ -z "\$PS1" \] && return\)/#\1/' ~/.bashrc
	sed -i '/case \$- in/,/esac/s/^/#/' ~/.bashrc

	#--------------------------------------------------

	export DEBIAN_FRONTEND=${DEBIAN_FRONTEND:-noninteractive}
	export TZ=${TIMEZONE:-"Etc/GMT"}

	ADMIN_EMAIL=${ADMIN_EMAIL:-"noreply@example.com"}

	export USER=${USER:-"user"}

	if [ -z "$DOMAIN" ]; then
    USE_VALID_SSL_CERTIFICATES="FALSE"
  else
    USE_VALID_SSL_CERTIFICATES="TRUE"
  fi

	DOMAIN=${DOMAIN:-""}

	AUTO_SIGN_IN=${AUTO_SIGN_IN:-"TRUE"}
	LOCK_APT=${LOCK_APT:-"TRUE"}

	FUN_FRONTEND_REPOSITORY_URL="${FUN_FRONTEND_REPOSITORY_URL:-https://github.com/funttastic/fun-hb-frontend.git}"
	FUN_FRONTEND_REPOSITORY_BRANCH="${FUN_FRONTEND_REPOSITORY_BRANCH:-production}"
	FUN_FRONTEND_COMMAND="${FUN_FRONTEND_COMMAND:-APP=fun-frontend yarn start --host}"
	FUN_FRONTEND_PORT="${FUN_FRONTEND_PORT:-50000}"

	FUN_CLIENT_REPOSITORY_URL="${FUN_CLIENT_REPOSITORY_URL:-https://github.com/funttastic/fun-hb-client.git}"
	FUN_CLIENT_REPOSITORY_BRANCH="${FUN_CLIENT_REPOSITORY_BRANCH:-production}"
	FUN_CLIENT_COMMAND="${FUN_CLIENT_COMMAND:-APP=fun-client python app.py}"
	FUN_CLIENT_PORT="${FUN_CLIENT_PORT:-50001}"

	HB_GATEWAY_REPOSITORY_URL=${HB_GATEWAY_REPOSITORY_URL:-https://github.com/Team-Kujira/gateway.git}
	HB_GATEWAY_REPOSITORY_BRANCH=${HB_GATEWAY_REPOSITORY_BRANCH:-production}
	HB_GATEWAY_COMMAND=${HB_GATEWAY_COMMAND:-APP=hb-gateway yarn start}
	HB_GATEWAY_PORT=${HB_GATEWAY_PORT:-15888}

	HB_CLIENT_REPOSITORY_URL=${HB_CLIENT_REPOSITORY_URL:-https://github.com/Team-Kujira/hummingbot.git}
	HB_CLIENT_REPOSITORY_BRANCH=${HB_CLIENT_REPOSITORY_BRANCH:-production}
	HB_CLIENT_COMMAND=${HB_CLIENT_COMMAND:-APP=hb-client python bin/hummingbot_quickstart.py; exit}

	FILEBROWSER_COMMAND=${FILEBROWSER_COMMAND:-APP=filebrowser filebrowser --address=0.0.0.0 -p \$FILEBROWSER_PORT -r ../shared}
	FILEBROWSER_PORT=${FILEBROWSER_PORT:-50002}

	#--------------------------------------------------

	apt-get update

	apt-get install --no-install-recommends -y \
		build-essential \
		ca-certificates \
		curl \
		gcc \
		git \
		gnutls-bin \
		jq \
		less \
		multitail \
		nginx \
		libsecret-1-0 \
		libssl-dev \
		libusb-1.0 \
		nano \
		openssh-server \
		pkg-config \
		psmisc \
		postgresql-server-dev-all \
		python3 \
		python3-dev \
		python3-pip \
		sudo \
		tmux \
		tree \
		vim


	#--------------------------------------------------
	adduser --gecos "" --disabled-password --home "/home/user" user
	set +x
	echo "user:$ADMIN_PASSWORD" | chpasswd
	set -x

	cp /etc/skel/.bashrc "/home/user"
	chown user:user "/home/user/.bashrc"

	#--------------------------------------------------

	echo -e "\n" >> /home/user/.bashrc

	echo "export ADMIN_EMAIL=\"$ADMIN_EMAIL\"" >> /home/user/.bashrc
	echo "export DOMAIN=\"$DOMAIN\"" >> /home/user/.bashrc
	echo "export USE_VALID_SSL_CERTIFICATES=\"$USE_VALID_SSL_CERTIFICATES\"" >> /home/user/.bashrc

	# Funttastic Client Frontend environment variables

	echo "export FUN_FRONTEND_REPOSITORY_URL=\"$FUN_FRONTEND_REPOSITORY_URL\"" >> /home/user/.bashrc
	echo "export FUN_FRONTEND_REPOSITORY_BRANCH=\"$FUN_FRONTEND_REPOSITORY_BRANCH\"" >> /home/user/.bashrc

	echo "export FUN_CLIENT_PROTOCOL=\"https\"" >> /home/user/.bashrc
	echo "export FUN_CLIENT_WEBSOCKET_PROTOCOL=\"wss\"" >> /home/user/.bashrc
	echo "export FUN_CLIENT_HOST=\"$DOMAIN\"" >> /home/user/.bashrc
	echo "export FUN_CLIENT_PORT=443" >> /home/user/.bashrc

	if [ -z "$FUN_FRONTEND_PORT" ]
	then
		echo 'export FUN_FRONTEND_PORT=50000' >> /home/user/.bashrc
	else
		echo "export FUN_FRONTEND_PORT=$FUN_FRONTEND_PORT" >> /home/user/.bashrc
	fi

	if [ -z "$FUN_FRONTEND_COMMAND" ]
	then
		echo "export FUN_FRONTEND_COMMAND=\"APP=fun-frontend yarn start --host\"" >> /home/user/.bashrc
	else
		echo "export FUN_FRONTEND_COMMAND=\"$FUN_FRONTEND_COMMAND\"" >> /home/user/.bashrc
	fi

	# FileBrowser environment variables

	if [ -z "$FILEBROWSER_PORT" ]
	then
		echo 'export FILEBROWSER_PORT=50002' >> /home/user/.bashrc
	else
		echo "export FILEBROWSER_PORT=$FILEBROWSER_PORT" >> /home/user/.bashrc
	fi
	echo 'export VITE_FILEBROWSER_PORT=$FILEBROWSER_PORT' >> /home/user/.bashrc

	if [ -z "$FILEBROWSER_COMMAND" ]
	then
		echo "export FILEBROWSER_COMMAND=\"APP=filebrowser filebrowser --address=0.0.0.0 -p \$FILEBROWSER_PORT -r ../shared\"" >> /home/user/.bashrc
	else
		echo "export FILEBROWSER_COMMAND=\"$FILEBROWSER_COMMAND\"" >> /home/user/.bashrc
	fi

	# Funttastic Client server environment variables

	echo "export FUN_CLIENT_REPOSITORY_URL=\"$FUN_CLIENT_REPOSITORY_URL\"" >> /home/user/.bashrc
	echo "export FUN_CLIENT_REPOSITORY_BRANCH=\"$FUN_CLIENT_REPOSITORY_BRANCH\"" >> /home/user/.bashrc

	if [ -z "$FUN_CLIENT_PORT" ]
	then
		echo 'export FUN_CLIENT_PORT=50001' >> /home/user/.bashrc
	else
		echo "export FUN_CLIENT_PORT=$FUN_CLIENT_PORT" >> /home/user/.bashrc
	fi

	if [ -z "$FUN_CLIENT_COMMAND" ]
	then
		echo "export FUN_CLIENT_COMMAND=\"APP=fun-client python app.py\"" >> /home/user/.bashrc
	else
		echo "export FUN_CLIENT_COMMAND=\"$FUN_CLIENT_COMMAND\"" >> /home/user/.bashrc
	fi

	# HB Gateway environment variables

	echo "export HB_GATEWAY_REPOSITORY_URL=\"$HB_GATEWAY_REPOSITORY_URL\"" >> /home/user/.bashrc
	echo "export HB_GATEWAY_REPOSITORY_BRANCH=\"$HB_GATEWAY_REPOSITORY_BRANCH\"" >> /home/user/.bashrc

	if [ -z "$HB_GATEWAY_PORT" ]
	then
		echo 'export HB_GATEWAY_PORT=15888' >> /home/user/.bashrc
	else
		echo "export HB_GATEWAY_PORT=$HB_GATEWAY_PORT" >> /home/user/.bashrc
	fi

	if [ -z "$HB_GATEWAY_COMMAND" ]
	then
		echo "export HB_GATEWAY_COMMAND=\"APP=hb-gateway yarn start\"" >> /home/user/.bashrc
	else
		echo "export HB_GATEWAY_COMMAND=\"$HB_GATEWAY_COMMAND\"" >> /home/user/.bashrc
	fi

	# HB Client environment variables

	echo "export HB_CLIENT_REPOSITORY_URL=\"$HB_CLIENT_REPOSITORY_URL\"" >> /home/user/.bashrc
	echo "export HB_CLIENT_REPOSITORY_BRANCH=\"$HB_CLIENT_REPOSITORY_BRANCH\"" >> /home/user/.bashrc

	if [ -z "$HB_CLIENT_COMMAND" ]
	then
		echo "export HB_CLIENT_COMMAND=\"APP=hb-client python bin/hummingbot_quickstart.py; exit\"" >> /home/user/.bashrc
	else
		echo "export HB_CLIENT_COMMAND=\"$HB_CLIENT_COMMAND\"" >> /home/user/.bashrc
	fi

	echo -e "\n" >> /home/user/.bashrc

	#--------------------------------------------------

	echo -e "\n" >> /home/user/.bashrc

	echo "export DEBIAN_FRONTEND=\"$DEBIAN_FRONTEND\"" >> /home/user/.bashrc
	echo "export TZ=\"$TZ\"" >> /home/user/.bashrc
	echo "export AUTO_SIGN_IN=\"$AUTO_SIGN_IN\"" >> /home/user/.bashrc
	echo "export LOCK_APT=\"$LOCK_APT\"" >> /home/user/.bashrc

	echo -e "\n" >> /home/user/.bashrc

  #--------------------------------------------------

	unlink /usr/bin/pip
	ln -s /usr/bin/python3 /usr/bin/python
	ln -s /usr/bin/pip3 /usr/bin/pip

	#--------------------------------------------------

	curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash
	rm -f get.sh

		#--------------------------------------------------

	cat <<'SUDOERS' > /etc/sudoers.d/user
user ALL=(ALL) NOPASSWD: /usr/sbin/service nginx start, /usr/sbin/service nginx reload, /usr/sbin/service nginx stop, /usr/sbin/service nginx status, /usr/sbin/nginx
SUDOERS
}

fun_install() {
	set -ex

#	local arguments=$@
#	fun_export_variables $arguments

	cd /home/user

	sed -i 's/^\([[:space:]]*\[ -z "\$PS1" \] && return\)/#\1/' /home/user/.bashrc
	sed -i '/case \$- in/,/esac/s/^/#/' ~/.bashrc

	source /home/user/.bashrc

	#--------------------------------------------------

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

	MINICONDA_EXTENSION=$FILE_EXTENSION

	echo "export ARCHITECTURE=$ARCHITECTURE" >> /home/user/.bashrc
	echo "export OS=$OS" >> /home/user/.bashrc
	echo "export FILE_EXTENSION=$FILE_EXTENSION" >> /home/user/.bashrc
	echo "export IS_RASPBERRY=$IS_RASPBERRY" >> /home/user/.bashrc
	echo "export MINICONDA_EXTENSION=$MINICONDA_EXTENSION" >> /home/user/.bashrc

	if [ "$ARCHITECTURE" == "aarch64" ]
	then
		echo "export ARCHITECTURE_SUFFIX=\"-$ARCHITECTURE\"" >> /home/user/.bashrc
		MINICONDA_VERSION="Mambaforge-$(uname)-$(uname -m).sh"
		MINICONDA_URL="https://github.com/conda-forge/miniforge/releases/latest/download/$MINICONDA_VERSION"
		ln -s /home/user/mambaforge /home/user/miniconda3
	else
		MINICONDA_VERSION="Miniconda3-py38_4.10.3-$OS-$ARCHITECTURE.$FILE_EXTENSION"
		MINICONDA_URL="https://repo.anaconda.com/miniconda/$MINICONDA_VERSION"
	fi

	curl -L "$MINICONDA_URL" -o "/home/user/miniconda.$MINICONDA_EXTENSION"
	/bin/bash "/home/user/miniconda.$MINICONDA_EXTENSION" -b
	rm "/home/user/miniconda.$MINICONDA_EXTENSION"

	echo 'export PATH=/home/user/miniconda3/bin:$PATH' >> /home/user/.bashrc

	. /home/user/.bashrc
	conda update -n base -c conda-forge conda -y
	conda clean -tipy

	echo "export MINICONDA_VERSION=$MINICONDA_VERSION" >> /home/user/.bashrc
	echo "export MINICONDA_URL=$MINICONDA_URL" >> /home/user/.bashrc

	conda init --all

	#--------------------------------------------------

	source /home/user/.bashrc

	git config --global http.postBuffer 524288000
  git config --global https.postBuffer 524288000
  git config --global core.compression 0
  git config --global http.lowSpeedLimit 0
  git config --global http.lowSpeedTime 999999
  git config --global http.version HTTP/1.1
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

	rm -rf /home/user/.cache

	#--------------------------------------------------

	source /home/user/.bashrc

	conda create -n certbot python=3.11 -y
	conda activate certbot
	conda install pip -y
	pip install --upgrade pip
	pip install certbot certbot-nginx

	#--------------------------------------------------

	mkdir -p /home/user/funttastic/client
	cd /home/user/funttastic/client

	git clone --depth 1 --no-single-branch -b $FUN_CLIENT_REPOSITORY_BRANCH $FUN_CLIENT_REPOSITORY_URL .

	conda env create -f environment.yml --solver=classic

	conda activate funttastic

	cp resources/configuration/production.example.yml resources/configuration/production.yml
	cp -a resources/strategies/templates/. resources/strategies

	#--------------------------------------------------

	source /home/user/.bashrc

	mkdir -p /home/user/funttastic/frontend
	cd /home/user/funttastic/frontend

	git clone --depth 1 --no-single-branch -b $FUN_FRONTEND_REPOSITORY_BRANCH $FUN_FRONTEND_REPOSITORY_URL .

	yarn install
	git rm -r --cached .

	#--------------------------------------------------

	#curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash
	#rm -f get.sh

	mkdir -p /home/user/filebrowser/branding/img
	cd /home/user/filebrowser

	filebrowser config init
	filebrowser config set --branding.name "Funttastic"
	filebrowser config set --branding.theme "dark"
	filebrowser config set --branding.files /home/user/filebrowser/branding
	filebrowser config set --port $FILEBROWSER_PORT
	filebrowser config set --baseurl /

	cp /home/user/funttastic/frontend/resources/assets/funttastic/logo/logo.svg branding/img/logo.svg

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

	#--------------------------------------------------

	source /home/user/.bashrc

	mkdir -p /home/user/hummingbot/gateway
	cd /home/user/hummingbot/gateway

	git clone --depth 1 --no-single-branch -b $HB_GATEWAY_REPOSITORY_BRANCH $HB_GATEWAY_REPOSITORY_URL .

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

	#--------------------------------------------------

	source /home/user/.bashrc

	mkdir -p /home/user/hummingbot/client
	cd /home/user/hummingbot/client

	git clone --depth 1 --no-single-branch -b $HB_CLIENT_REPOSITORY_BRANCH $HB_CLIENT_REPOSITORY_URL .

	MINICONDA_ENVIRONMENT=$(head -1 setup/environment.yml | cut -d' ' -f2)
	if [ -z "$MINICONDA_ENVIRONMENT" ]
	then
		echo "The MINICONDA_ENVIRONMENT environment variable could not be defined."
		exit 1
	fi
	echo "export MINICONDA_ENVIRONMENT=$MINICONDA_ENVIRONMENT" >> /home/user/.bashrc

	conda env create -f setup/environment.yml --solver=classic
	conda clean -tipy
	rm -rf /home/user/.cache

	echo "source /home/user/miniconda3/etc/profile.d/conda.sh && conda activate $MINICONDA_ENVIRONMENT" >> /home/user/.bashrc
	/home/user/miniconda3/envs/$MINICONDA_ENVIRONMENT/bin/python3 setup.py build_ext --inplace -j 8
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

	#--------------------------------------------------

	source /home/user/.bashrc

	conda activate funttastic
	cd /home/user/funttastic/client
	pip install -r requirements.txt

	sed -i -e "/server:/,/port: [0-9]*/ s/port: [0-9]*/port: $FUN_CLIENT_PORT/" /home/user/funttastic/client/resources/configuration/production.yml
	sed -i -e '/logging:/,/use_telegram:/ s/use_telegram:.*/use_telegram: false/' -e '/telegram:/,/enabled:/ s/enabled:.*/enabled: false/' -e '/telegram:/,/listen_commands:/ s/listen_commands:.*/listen_commands: false/' /home/user/funttastic/client/resources/configuration/production.yml
	sed -i -e '/telegram:/,/enabled:/ s/enabled:.*/enabled: false/' -e '/telegram:/,/listen_commands:/ s/listen_commands:.*/listen_commands: false/' /home/user/funttastic/client/resources/configuration/common.yml

	#--------------------------------------------------

	mkdir -p /home/user/shared/logs/tmux
  ln -s /home/user/funttastic/client/resources/logs /home/user/shared/logs/fun-client
  ln -s /home/user/hummingbot/gateway/logs /home/user/shared/logs/hb-gateway
  ln -s /home/user/hummingbot/client/logs /home/user/shared/logs/hb-client

  mkdir -p /home/user/shared/scripts

  cat <<'SCRIPT' > /home/user/shared/scripts/functions.sh
#!/bin/bash

replace_in_file() {
	local function_name="replace_in_file"
	local file_path="$1"
	local search_regex="$2"
	local substitution_regex="$3"

	 python /home/user/shared/scripts/functions.py "$function_name" "$file_path" "$search_regex" "$substitution_regex"
}

replace_environment_variable() {
	local function_name="replace_environment_variable"
	local file_path="$1"
	local variable_name="$2"
	local new_value="$3"

	python /home/user/shared/scripts/functions.py "$function_name" "$file_path" "$variable_name" "$new_value"
}

start_nginx() {
	local session="nginx"

	if [ "$(is_session_running "$session")" = "FALSE" ]; then
		tmux new-session -d -s "$session" \; pipe-pane -o "cat >> /home/user/shared/logs/tmux/$session.log"

		tmux send-keys -t "$session" "/usr/sbin/nginx -g 'daemon off;'" C-m
	fi
}

start_fun_frontend() {
	local session="fun-frontend"

	if [ "$(is_session_running "$session")" = "FALSE" ]; then
		tmux new-session -d -s "$session" \; pipe-pane -o "cat >> /home/user/shared/logs/tmux/$session.log"

		tmux send-keys -t "$session" "cd /home/user/funttastic/frontend" C-m
		tmux send-keys -t "$session" "$FUN_FRONTEND_COMMAND" C-m
	fi
}

start_filebrowser() {
	local session="filebrowser"

	if [ "$(is_session_running "$session")" = "FALSE" ]; then
		tmux new-session -d -s "$session" \; pipe-pane -o "cat >> /home/user/shared/logs/tmux/$session.log"

		tmux send-keys -t "$session" "cd /home/user/filebrowser" C-m
		tmux send-keys -t "$session" "$FILEBROWSER_COMMAND" C-m
	fi
}

start_fun_client() {
	local password="$1"
	local session="fun-client"

	if [ "$(is_session_running "$session")" = "FALSE" ]; then
		tmux new-session -d -s "$session" \; pipe-pane -o "cat >> /home/user/shared/logs/tmux/$session.log"

#		tmux set-environment -t "$session" PASSWORD "$password"
#		tmux send-keys -t "$session" "export PASSWORD=\"$(tmux show-environment PASSWORD | cut -d= -f2)\"" C-m
		tmux send-keys -t "$session" "export PASSWORD=\"$password\"" C-m
		tmux send-keys -t "$session" "conda activate funttastic" C-m
		tmux send-keys -t "$session" "cd /home/user/funttastic/client" C-m
		tmux send-keys -t "$session" "$FUN_CLIENT_COMMAND" ^m
		tmux send-keys -t "$session"  Enter
#		tmux set-environment -t "$session" -u PASSWORD
	fi
}

start_hb_gateway() {
	local password="$1"
	local session="hb-gateway"

	if [ "$(is_session_running "$session")" = "FALSE" ]; then
		tmux new-session -d -s "$session" \; pipe-pane -o "cat >> /home/user/shared/logs/tmux/$session.log"

#		tmux set-environment -t "$session" GATEWAY_PASSPHRASE "$password"
#		tmux send-keys -t "$session" "export GATEWAY_PASSPHRASE=\"$(tmux show-environment GATEWAY_PASSPHRASE | cut -d= -f2)\"" C-m
		tmux send-keys -t "$session" "export GATEWAY_PASSPHRASE=\"$password\"" C-m
		tmux send-keys -t "$session" "cd /home/user/hummingbot/gateway" C-m
		tmux send-keys -t "$session" "$HB_GATEWAY_COMMAND" C-m
		tmux set-environment -t "$session" -u GATEWAY_PASSPHRASE
	fi
}

start_hb_client() {
	local session="hb-client"

	if [ "$(is_session_running "$session")" = "FALSE" ]; then
		tmux new-session -d -s "$session" \; pipe-pane -o "cat >> /home/user/shared/logs/tmux/$session.log"

		tmux send-keys -t "$session" "conda activate hummingbot" C-m
		tmux send-keys -t "$session" "cd /home/user/hummingbot/client" C-m
		tmux send-keys -t "$session" "$HB_CLIENT_COMMAND" C-m
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

	start_nginx
	start_fun_frontend
	start_filebrowser
	start_fun_client "$password"
	start_hb_gateway "$password"
	start_hb_client
}

start() {
	source /home/user/.bashrc

	local credentials
	local username="${1:-$ADMIN_USERNAME}"
	local password="${2:-$ADMIN_PASSWORD}"

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

	if [[ -n "$username" && -n "$password"  ]]; then
		credentials=$(authenticate "$username" "$password")
#	elif [ -f "/home/user/.temp_credentials" ]; then
#		# This condition is only for the first start.
#
#		username=$(grep "username" "/home/user/.temp_credentials" | cut -d'=' -f2)
#		password=$(grep "password" "/home/user/.temp_credentials" | cut -d'=' -f2)
#
#		credentials=$(authenticate "$username" "$password")
#
#		if [ -n "$credentials" ]; then
#			rm -f /home/user/.temp_credentials
#		fi
	else
		credentials=$(authenticate)
	fi

	if [ -z "$credentials" ] || echo "$credentials" | grep -iq "error"; then
		echo "$credentials" >&2
		return 1
	else
		username=$(extract_from_json "username" "$credentials")
		password=$(extract_from_json "password" "$credentials")
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
			--start_nginx)
				start_nginx
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

start_and_keep() {
	start
	keep
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

stop_nginx() {
	tmux kill-session -t "nginx"
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
	stop_nginx
	stop_fun_frontend
	stop_filebrowser
	stop_fun_client
	stop_hb_gateway
	stop_hb_client
}

stop() {
	source /home/user/.bashrc

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
			--stop_nginx)
				stop_nginx
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
	local encrypted_message_base64=$(echo "$message" | openssl pkeyutl -encrypt -pubin -inkey /home/user/.ssh/id_rsa_openssl.pub.pem -pkeyopt rsa_padding_mode:oaep | base64)

	echo "$encrypted_message_base64"
}

decrypt_message() {
	local encrypted_message_base64=$1

	# Decode the Base64 encrypted message and decrypt it directly
	local decrypted_message=$(echo "$encrypted_message_base64" | base64 --decode | openssl pkeyutl -decrypt -inkey /home/user/.ssh/id_rsa -pkeyopt rsa_padding_mode:oaep)

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

extract_from_json() {
	local path=$1
	local json=$2

	echo $json | /usr/bin/jq -r ".$path"
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

	credentials_json="{\"username\":\"$username\",\"password\":\"$password\"}"

	echo "$credentials_json"
}

authenticate() {
	local username="$1"
	local password="$2"

	if [ ! -f "/home/user/.ssh/id_rsa" ] || { [[ -n "$username" ]] && [[ -n "$password" ]]; }; then
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

log_all () {
	tail -f \
		/home/user/shared/logs/tmux/fun-frontend.log \
		/home/user/shared/logs/tmux/filebrowser.log \
		/home/user/shared/logs/tmux/fun-client.log \
		/home/user/shared/logs/tmux/hb-gateway.log \
		/home/user/shared/logs/fun-client/all.log \
		/home/user/shared/logs/hb-gateway/* \
		/home/user/shared/logs/hb-client/*
}

quick_deploy_fun_hb_client () {
	set -ex

	local branch="$1"

	cd /home/user/funttastic/client || { echo "Failed to open the repository folder..."; return 1; }

	unlink /home/user/funttastic/client/resources

	git reset

	git stash

	if [ -n "$branch" ]; then
		current_branch_name=$(git rev-parse --abbrev-ref HEAD)

		if [ ! "$branch" == "$current_branch_name" ]; then
			git switch "$current_branch_name"
		fi
	fi

	git fetch --all
	git pull

	rm -rf /home/user/funttastic/client/resources

	ln -s /home/user/shared/funttastic/client/resources /home/user/funttastic/client/resources

	git stash apply

	cd /home/user || return

	set +ex
}

SCRIPT

cat <<'SCRIPT' > /home/user/shared/scripts/functions.py
import sys
import re


def escape_shell_value(value):
	"""Escape characters for shell variables."""
	value = re.sub(r'(["\\])', r'\\\1', value)  # Escape quotes and backslashes
	value = re.sub(r'\n', r'\\n', value)  # Escape newlines
	return value


def replace_in_file(file_path, search_regex, substitution_regex):
	with open(file_path, 'r') as file:
		content = file.read()

	new_content = re.sub(search_regex, substitution_regex, content, flags=re.MULTILINE)

	with open(file_path, 'w') as file:
		file.write(new_content)


def replace_environment_variable(file_path, variable_name, new_value):
	"""
	Replace or add the content of an environment variable in a file.

	:param file_path: Path to the file to update.
	:param variable_name: Name of the variable to replace.
	:param new_value: New value to set for the variable.
	"""
	# Escape the new value
	escaped_value = escape_shell_value(new_value)

	# Prepare the regex pattern for matching the variable line
	var_pattern = re.compile(
		rf'^(export\s+{re.escape(variable_name)}=.*?)(?=\nexport|\Z)',  # Match until the next export or end of file
		re.DOTALL | re.MULTILINE
	)

	# Replacement line
	replacement_line = f'export {variable_name}="{escaped_value}"'

	# Read the file
	with open(file_path, 'r') as file:
		content = file.read()

	# Check if the variable exists and replace it
	if var_pattern.search(content):
		content = var_pattern.sub(replacement_line, content)
	else:
		# If variable not found, append it to the file
		if content.strip() == "":
			content = replacement_line
		else:
			content += '\n' + replacement_line

	# Write the updated content back to the file
	with open(file_path, 'w') as file:
		file.write(content)


if __name__ == "__main__":
	if sys.argv[1] == "replace_environment_variable":
		if len(sys.argv) != 5:
			print("Usage: python functions.py function_name /path/to/file VARIABLE_NAME \"new_value\"")
			sys.exit(1)

		function_name = f"""{sys.argv[1]}"""
		file_path = f"""{sys.argv[2]}"""
		variable_name = f"""{sys.argv[3]}"""
		new_value = f"""{sys.argv[4]}"""

		module = sys.modules[__name__]
		function = getattr(module, function_name)

		result = function(file_path, variable_name, new_value)

		print(result)
	else:
		raise ValueError(f"Function {sys.argv[1]} not found.")
SCRIPT

	chmod +x /home/user/shared/scripts/functions.sh
	chmod +x /home/user/shared/scripts/functions.py

	cat <<'SCRIPT' > /home/user/shared/scripts/initialize.sh
#!/bin/bash

source /home/user/shared/scripts/functions.sh

SCRIPT

	echo "source /home/user/shared/scripts/initialize.sh" >> /home/user/.bashrc

	source /home/user/.bashrc


	#--------------------------------------------------

	local arguments=$@
	fun_export_variables $arguments

	source /home/user/.bashrc

	# Certificates
	#--------------------------------------------------
	mkdir -p /home/user/shared/common/certificates/api

  # For using a self signed certificate
	conda activate funttastic
	python /home/user/funttastic/client/resources/scripts/generate_ssl_certificates.py --passphrase $ADMIN_PASSWORD --cert-path /home/user/shared/common/certificates/api

	# HB Client
	conda activate hummingbot
	python /home/user/funttastic/client/resources/scripts/generate_hb_client_password_verification_file.py -p "$ADMIN_PASSWORD" -d /home/user/hummingbot/client/conf

	# Fun Client

	# Fun Frontend

	# Filebrowser
	cd /home/user/filebrowser
	filebrowser users add $ADMIN_USERNAME $ADMIN_PASSWORD --perm.admin
#	filebrowser users update $ADMIN_USERNAME --commands="ls,git,tree,curl,rm,mkdir,pwd,cp,mv,cat,less,find,touch,echo,chmod,chown,df,du,ps,kill"

	mkdir -p /home/user/.ssh
	chmod 0700 /home/user/.ssh
	cd /home/user/.ssh/

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

	credentials_json="{\"username\":\"$escaped_admin_username\",\"password\":\"$escaped_admin_password\"}"

	ENCRYPTED_CREDENTIALS_BASE64=$(encrypt_message "$credentials_json")

	# Necessary because the cipher generated with OpenSSL is not always the same
	NON_ENCRYPTED_CREDENTIALS_JSON_SHA256SUM=$(generate_sha256sum "$credentials_json")

	echo "# Credentials Section - Begin" >> /home/user/.bashrc
	echo "export ENCRYPTED_CREDENTIALS=\"$ENCRYPTED_CREDENTIALS_BASE64\"" >> /home/user/.bashrc
	echo "export NON_ENCRYPTED_CREDENTIALS_SHA256SUM=\"$NON_ENCRYPTED_CREDENTIALS_JSON_SHA256SUM\"" >> /home/user/.bashrc
	echo "# Credentials Section - End" >> /home/user/.bashrc

	# Necessary because the CMD instruction does not work with variables of type ARG, only of type ENV
	# We cannot convert the ADMIN_USERNAME and ADMIN_PASSWORD variables to ENV for security reasons
	echo "username=$ADMIN_USERNAME" > /home/user/.temp_credentials
	echo "password=$ADMIN_PASSWORD" >> /home/user/.temp_credentials

	if [ ! "$AUTO_SIGN_IN" == "TRUE" ]; then
		rm -f /home/user/.ssh/id_rsa
		rm -f /home/user/.ssh/id_rsa_openssl.pem
	fi

  set -x

	#--------------------------------------------------

	mkdir -p \
  		/home/user/shared/common \
  		/home/user/shared/funttastic/client \
  		/home/user/shared/hummingbot/client \
  		/home/user/shared/hummingbot/gateway

	rm -rf /home/user/funttastic/client/resources/certificates
	rm -rf /home/user/hummingbot/client/certs
	rm -rf /home/user/hummingbot/gateway/certs
	ln -s /home/user/shared/common/certificates/api /home/user/funttastic/client/resources/certificates
	ln -s /home/user/shared/common/certificates/api /home/user/hummingbot/gateway/certs
	ln -s /home/user/shared/common/certificates/api /home/user/hummingbot/client/certs

	mv /home/user/funttastic/client/resources /home/user/shared/funttastic/client/
	ln -s /home/user/shared/funttastic/client/resources /home/user/funttastic/client/resources

	mv /home/user/hummingbot/gateway/db /home/user/shared/hummingbot/gateway/
	mv /home/user/hummingbot/gateway/conf /home/user/shared/hummingbot/gateway/
	mv /home/user/hummingbot/gateway/logs /home/user/shared/hummingbot/gateway/
	ln -s /home/user/shared/hummingbot/gateway/db /home/user/hummingbot/gateway/db
	ln -s /home/user/shared/hummingbot/gateway/conf /home/user/hummingbot/gateway/conf
	ln -s /home/user/shared/hummingbot/gateway/logs /home/user/hummingbot/gateway/logs

	mv /home/user/hummingbot/client/conf /home/user/shared/hummingbot/client/
	mv /home/user/hummingbot/client/logs /home/user/shared/hummingbot/client/
	mv /home/user/hummingbot/client/data /home/user/shared/hummingbot/client/
	mv /home/user/hummingbot/client/scripts /home/user/shared/hummingbot/client/
	mv /home/user/hummingbot/client/pmm_scripts /home/user/shared/hummingbot/client/
	ln -s /home/user/shared/hummingbot/client/conf /home/user/hummingbot/client/conf
	ln -s /home/user/shared/hummingbot/client/logs /home/user/hummingbot/client/logs
	ln -s /home/user/shared/hummingbot/client/data /home/user/hummingbot/client/data
	ln -s /home/user/shared/hummingbot/client/scripts /home/user/hummingbot/client/scripts
	ln -s /home/user/shared/hummingbot/client/pmm_scripts /home/user/hummingbot/client/pmm_scripts
}

fun_post_install() {
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

	mkdir -p /root/shared/scripts

	cat <<'SCRIPT' > /root/shared/scripts/initialize.sh
#!/bin/bash

arguments=$*

echo $arguments

source /root/shared/scripts/functions.sh $arguments
SCRIPT

	chmod +x /root/shared/scripts/initialize.sh

	cat <<'SCRIPT' > /root/shared/scripts/functions.sh
#!/bin/bash

replace_in_file() {
	local function_name="replace_in_file"
	local file_path="$1"
	local search_regex="$2"
	local substitution_regex="$3"

	 python /home/user/shared/scripts/functions.py "$function_name" "$file_path" "$search_regex" "$substitution_regex"
}

replace_environment_variable() {
	local function_name="replace_environment_variable"
	local file_path="$1"
	local variable_name="$2"
	local new_value="$3"

	python /home/user/shared/scripts/functions.py "$function_name" "$file_path" "$variable_name" "$new_value"
}

change_user_and_password() {
	local username=$1
	local password=$2

	output=$(sudo -u user -i <<USER
		source ~/shared/scripts/functions.sh
		escaped_admin_username=\$(escape_string "$username")
		escaped_admin_password=\$(escape_string "$password")
		echo "\$escaped_admin_username:\$escaped_admin_password"
USER
	)

	escaped_admin_username=$(echo "$output" | cut -d':' -f1)
	escaped_admin_password=$(echo "$output" | cut -d':' -f2)

	echo "user:$password" | sudo chpasswd

	cd /home/user
	sudo -u user -i env ADMIN_USERNAME=$escaped_admin_username ADMIN_PASSWORD=$escaped_admin_password bash <<'USER'
	  source ~/.bashrc

			# Updating credentials
			credentials_json="{\"username\":\"$ADMIN_USERNAME\",\"password\":\"$ADMIN_PASSWORD\"}"

			ENCRYPTED_CREDENTIALS_BASE64=$(encrypt_message "$credentials_json")
			NON_ENCRYPTED_CREDENTIALS_JSON_SHA256SUM=$(generate_sha256sum "$credentials_json")
			replace_environment_variable /home/user/.bashrc ENCRYPTED_CREDENTIALS "$ENCRYPTED_CREDENTIALS_BASE64"
			replace_environment_variable /home/user/.bashrc NON_ENCRYPTED_CREDENTIALS_SHA256SUM "$NON_ENCRYPTED_CREDENTIALS_JSON_SHA256SUM"

			# Updating filebrowser credentials
			filebrowser users update user --username $ADMIN_USERNAME --password $ADMIN_PASSWORD -d /home/user/filebrowser/filebrowser.db

			# Updating certificates
			conda activate funttastic
			rm -rf /home/user/shared/common/certificates/api
			mkdir -p /home/user/shared/common/certificates/api
			python /home/user/funttastic/client/resources/scripts/generate_ssl_certificates.py --passphrase $ADMIN_PASSWORD --cert-path /home/user/shared/common/certificates/api

			# Updating Hummingbot Client credentials
			conda activate hummingbot
			python /home/user/funttastic/client/resources/scripts/generate_hb_client_password_verification_file.py -p "$ADMIN_PASSWORD" -d /home/user/hummingbot/client/conf
USER
}

generate_valid_ssl_certificates() {
  local current_username="user"
  local email=$1
  local password=$2
  local domain=$3

  set -ex

	replace_environment_variable /home/user/.bashrc ADMIN_EMAIL "$email"
	replace_environment_variable /home/user/.bashrc DOMAIN "$domain"
	replace_environment_variable /home/user/.bashrc FUN_CLIENT_PROTOCOL "https"
	replace_environment_variable /home/user/.bashrc FUN_CLIENT_WEBSOCKET_PROTOCOL "wss"
	replace_environment_variable /home/user/.bashrc FUN_CLIENT_HOST "$domain"
	replace_environment_variable /home/user/.bashrc FUN_CLIENT_PORT "443"


  ln -s "/home/$current_username/miniconda3/envs/certbot/bin/certbot" "/usr/bin/certbot"

	# certbot certonly --nginx --non-interactive --agree-tos -m $ADMIN_EMAIL -d $domain

  mkdir -p "/home/$current_username/shared/common/certificates/$domain"

  ln -s "/etc/letsencrypt/archive/$domain/cert1.pem" "/home/$current_username/shared/common/certificates/$domain/cert1.pem"
  ln -s "/etc/letsencrypt/archive/$domain/chain1.pem" "/home/$current_username/shared/common/certificates/$domain/chain1.pem"
  ln -s "/etc/letsencrypt/archive/$domain/fullchain1.pem" "/home/$current_username/shared/common/certificates/$domain/fullchain1.pem"
  ln -s "/etc/letsencrypt/archive/$domain/privkey1.pem" "/home/$current_username/shared/common/certificates/$domain/privkey1.pem"

	chown -R $current_username:$current_username "/etc/letsencrypt/archive/$domain"
  chown -R $current_username:$current_username "/home/$current_username/shared/common/certificates"

  cat <<NGINX > /etc/nginx/conf.d/$domain.conf
server {
	listen 80;
	server_name $domain www.$domain;

	return 301 https://\$host\$request_uri;
}

server {
	listen 443 ssl;
	server_name $domain www.$domain;

	ssl_certificate /home/$current_username/shared/common/certificates/$domain/fullchain1.pem;
	ssl_certificate_key /home/$current_username/shared/common/certificates/$domain/privkey1.pem;
	ssl_client_certificate /home/$current_username/shared/common/certificates/$domain/chain1.pem;

	location / {
		proxy_pass http://localhost:50000;

		proxy_set_header Host \$host;
		proxy_set_header X-Real-IP \$remote_addr;
		proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
		proxy_set_header X-Forwarded-Proto \$scheme;

		proxy_ssl_certificate /home/$current_username/shared/common/certificates/api/client_cert.pem;
		proxy_ssl_certificate_key /home/$current_username/shared/common/certificates/api/client_key.pem;
		proxy_ssl_trusted_certificate /home/$current_username/shared/common/certificates/api/ca_cert.pem;
	}

	location /api/ws {
		rewrite ^/api/ws/(.*)\$ /ws/\$1 break;

		proxy_pass https://localhost:50001;

		proxy_set_header Host \$host;
		proxy_set_header X-Real-IP \$remote_addr;
		proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
		proxy_set_header X-Forwarded-Proto \$scheme;

		proxy_http_version 1.1;
		proxy_set_header Upgrade \$http_upgrade;
		proxy_set_header Connection "Upgrade";

		proxy_ssl_certificate /home/$current_username/shared/common/certificates/api/client_cert.pem;
		proxy_ssl_certificate_key /home/$current_username/shared/common/certificates/api/client_key.pem;
		proxy_ssl_trusted_certificate /home/$current_username/shared/common/certificates/api/ca_cert.pem;

		proxy_ssl_protocols TLSv1.2 TLSv1.3;
		proxy_ssl_ciphers HIGH:!aNULL:!MD5;

		proxy_ssl_verify on;
		proxy_ssl_verify_depth 3;
		proxy_ssl_session_reuse on;
	}

	location /api {
		rewrite ^/api/(.*)\$ /\$1 break;

		proxy_pass https://localhost:50001;

		proxy_set_header Host \$host;
		proxy_set_header X-Real-IP \$remote_addr;
		proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
		proxy_set_header X-Forwarded-Proto \$scheme;

		proxy_ssl_certificate /home/$current_username/shared/common/certificates/api/client_cert.pem;
		proxy_ssl_certificate_key /home/$current_username/shared/common/certificates/api/client_key.pem;
		proxy_ssl_trusted_certificate /home/$current_username/shared/common/certificates/api/ca_cert.pem;

		proxy_ssl_protocols TLSv1.2 TLSv1.3;
		proxy_ssl_ciphers HIGH:!aNULL:!MD5;

		proxy_ssl_verify on;
		proxy_ssl_verify_depth 3;
		proxy_ssl_session_reuse on;
	}
}
NGINX

	service nginx start

  set +ex
}

stop() {
	cd /home/user
	sudo -u user -i <<USER
  	source ~/.bashrc
  	stop
USER
}

start_and_keep() {
	cd /home/user
	sudo -u user -i <<USER
  	source ~/.bashrc
  	start_and_keep
USER
}

FIRST_RUN_LOCK="~/shared/scripts/first_run.lock"

if [ ! -f "$FIRST_RUN_LOCK" ]; then
	export IS_FIRST_RUN="TRUE"
	rm -f "$FIRST_RUN_LOCK"
else
	export IS_FIRST_RUN="FALSE"
fi

if [ "$IS_FIRST_RUN" == "TRUE" ]
then
	change_user_and_password $ADMIN_USERNAME $ADMIN_PASSWORD

	if [ "$USE_VALID_SSL_CERTIFICATES" = "TRUE" ]; then
		generate_valid_ssl_certificates $ADMIN_EMAIL $ADMIN_PASSWORD $DOMAIN
	fi
fi

if [ "$1" == "start_and_keep" ]
then
  stop
	start_and_keep
fi

SCRIPT

	chmod +x /root/shared/scripts/functions.sh

	touch ~/shared/scripts/first_run.lock
}
