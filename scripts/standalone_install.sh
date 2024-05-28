#!/bin/bash

# Usage:
# source standalone_install.sh
#	bash -l standalone_install --username=<username> --password=<password> --auto_sign_in=<auto_sign_in> --lock-apt=<lock_apt> --fun-frontend-repository-url=<fun_frontend_repository_url> --fun-frontend-repository-branch=<fun_frontend_repository_branch> --fun-frontend-command=<fun_frontend_command> --fun-frontend-port=<fun_frontend_port> --fun-client-repository-url=<fun_client_repository_url> --fun-client-repository-branch=<fun_client_repository_branch> --fun-client-command=<fun_client_command> --fun-client-port=<fun_client_port> --hb-gateway-repository-url=<hb_gateway_repository_url> --hb-gateway-repository-branch=<hb_gateway_repository_branch> --hb-gateway-command=<hb_gateway_command> --hb-gateway-port=<hb_gateway_port> --hb-client-repository-url=<hb_client_repository_url> --hb-client-repository-branch=<hb_client_repository_branch> --hb-client-command=<hb_client_command> --filebrowser-command=<filebrowser_command> --filebrowser-port=<filebrowser_port>

# To test it, you can create a docker ubuntu container as following:

#image_name=ubuntu
#container_name=standalone-fun-kuji-hb
#
#docker rm -f $container_name
#
#docker run \
#
#	-dit \
#	--log-opt max-size=10m \
#	--log-opt max-file=5 \
#	--name $container_name \
#	--network "bridge" \
#	--mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
#	-p "50000":"50000" \
#	-p "50001":"50001" \
#	-p "50002":"50002" \
#	-p "15888":"15888" \
#	-p "50022":"22" \
#	$image_name:latest \
#	tail -f /dev/null
#
#docker exec -it $container_name mkdir ~/temporary
#docker cp ./scripts/standalone_install.sh $container_name:~/temporary/standalone_install.sh
#docker exec -it $container_name chmod +x ~/temporary/standalone_install.sh
#docker exec -it $container_name chmod 777 ~/temporary/standalone_install.sh
#docker exec -it $container_name bash -c "source ~/temporary/standalone_install.sh && standalone_install --username=<username> --password=<password> --auto-sign-in=TRUE --lock-apt=FALSE"

standalone_install() {
	set -ex

	args=("$@")

	pre_install "${args[@]}"

	sudo -u $USER -i <<USER
		env
		source ~/.bashrc
		source /root/temporary/standalone_install.sh
		# Forward the arguments to the install function
		install "${args[@]}"
USER

	post_install "${args[@]}"
}


pre_install() {
	set -ex

	chsh -s /bin/bash
	rm /usr/bin/sh
	ln -s /bin/bash /usr/bin/sh

	sed -i 's/^\([[:space:]]*\[ -z "\$PS1" \] && return\)/#\1/' ~/.bashrc

	#--------------------------------------------------

	local ADMIN_USERNAME=""
	local ADMIN_PASSWORD=""
	local ADMIN_EMAIL=""

	local DOMAIN=""

	local AUTO_SIGN_IN=""
	local LOCK_APT=""

	local FUN_FRONTEND_REPOSITORY_URL=""
	local FUN_FRONTEND_REPOSITORY_BRANCH=""
	local FUN_FRONTEND_COMMAND=""
	local FUN_FRONTEND_PORT=""

	local FUN_CLIENT_REPOSITORY_URL=""
	local FUN_CLIENT_REPOSITORY_BRANCH=""
	local FUN_CLIENT_COMMAND=""
	local FUN_CLIENT_PORT=""

	local HB_GATEWAY_REPOSITORY_URL=""
	local HB_GATEWAY_REPOSITORY_BRANCH=""
	local HB_GATEWAY_COMMAND=""
	local HB_GATEWAY_PORT=""

	local HB_CLIENT_REPOSITORY_URL=""
	local HB_CLIENT_REPOSITORY_BRANCH=""
	local HB_CLIENT_COMMAND=""

	local FILEBROWSER_COMMAND=""
	local FILEBROWSER_PORT=""

	local USE_VALID_SSL_CERTIFICATES="FALSE"

	#--------------------------------------------------

	while [[ $# -gt 0 ]]; do
		case "$1" in
			--username=*)
				set +x
				ADMIN_USERNAME="${1#*=}"
				set -x
				;;
			--password=*)
				set +x
				ADMIN_PASSWORD="${1#*=}"
				set -x
				;;
			--email=*)
				ADMIN_EMAIL="${1#*=}"
				;;
			--user=*)
				USER="${1#*=}"
				;;
			--domain=*)
				DOMAIN="${1#*=}"
				;;
			--auto-sign-in=*)
				AUTO_SIGN_IN="${1#*=}"
				;;
			--lock-apt=*)
				LOCK_APT="${1#*=}"
				;;
			--fun-frontend-repository-url=*)
				FUN_FRONTEND_REPOSITORY_URL="${1#*=}"
				;;
			--fun-frontend-repository-branch=*)
				FUN_FRONTEND_REPOSITORY_BRANCH="${1#*=}"
				;;
			--fun-frontend-command=*)
				FUN_FRONTEND_COMMAND="${1#*=}"
				;;
			--fun-frontend-port=*)
				FUN_FRONTEND_PORT="${1#*=}"
				;;
			--fun-client-repository-url=*)
				FUN_CLIENT_REPOSITORY_URL="${1#*=}"
				;;
			--fun-client-repository-branch=*)
				FUN_CLIENT_REPOSITORY_BRANCH="${1#*=}"
				;;
			--fun-client-command=*)
				FUN_CLIENT_COMMAND="${1#*=}"
				;;
			--fun-client-port=*)
				FUN_CLIENT_PORT="${1#*=}"
				;;
			--hb-gateway-repository-url=*)
				HB_GATEWAY_REPOSITORY_URL="${1#*=}"
				;;
			--hb-gateway-repository-branch=*)
				HB_GATEWAY_REPOSITORY_BRANCH="${1#*=}"
				;;
			--hb-gateway-command=*)
				HB_GATEWAY_COMMAND="${1#*=}"
				;;
			--hb-gateway-port=*)
				HB_GATEWAY_PORT="${1#*=}"
				;;
			--hb-client-repository-url=*)
				HB_CLIENT_REPOSITORY_URL="${1#*=}"
				;;
			--hb-client-repository-branch=*)
				HB_CLIENT_REPOSITORY_BRANCH="${1#*=}"
				;;
			--hb-client-command=*)
				HB_CLIENT_COMMAND="${1#*=}"
				;;
			--filebrowser-command=*)
				FILEBROWSER_COMMAND="${1#*=}"
				;;
			--filebrowser-port=*)
				FILEBROWSER_PORT="${1#*=}"
				;;
			*)
		esac
		shift
	done

	#--------------------------------------------------

	export DEBIAN_FRONTEND=${DEBIAN_FRONTEND:-noninteractive}
	export TZ=${TIMEZONE:-"Etc/GMT"}

	ADMIN_EMAIL=${ADMIN_EMAIL:-"noreply@example.com"}

	USER=${USER:-"user"}

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
		certbot \
		curl \
		gcc \
		git \
		jq \
		less \
		multitail \
		nginx \
		libsecret-1-0 \
		libssl-dev \
		libusb-1.0 \
		pkg-config \
		psmisc \
		openssh-server \
		postgresql-server-dev-all \
		python3 \
		python3-certbot-apache \
		python3-certbot-nginx \
		python3-dev \
		python3-pip \
		tmux \
		tree \
		vim

	#--------------------------------------------------

	adduser --gecos "" --disabled-password --home "/home/$USER" $USER
	echo "$USER:$ADMIN_PASSWORD" | chpasswd
	usermod -aG sudo $USER

	cp /etc/skel/.bashrc "/home/$USER"
	chown $USER:$USER "/home/$USER/.bashrc"

	#--------------------------------------------------

	echo -e "\n" >> /home/$USER/.bashrc

	echo "export ADMIN_EMAIL=\"$ADMIN_EMAIL\"" >> /home/$USER/.bashrc
	echo "export USER=\"$USER\"" >> /home/$USER/.bashrc
	echo "export DOMAIN=\"$DOMAIN\"" >> /home/$USER/.bashrc
	echo "export USE_VALID_SSL_CERTIFICATES=\"$USE_VALID_SSL_CERTIFICATES\"" >> /home/$USER/.bashrc

	# Funttastic Client Frontend environment variables

	echo "export FUN_FRONTEND_REPOSITORY_URL=\"$FUN_FRONTEND_REPOSITORY_URL\"" >> /home/$USER/.bashrc
	echo "export FUN_FRONTEND_REPOSITORY_BRANCH=\"$FUN_FRONTEND_REPOSITORY_BRANCH\"" >> /home/$USER/.bashrc

	if [ -z "$FUN_FRONTEND_PORT" ]
	then
		echo 'export FUN_FRONTEND_PORT=50000' >> /home/$USER/.bashrc
	else
		echo "export FUN_FRONTEND_PORT=$FUN_FRONTEND_PORT" >> /home/$USER/.bashrc
	fi

	if [ -z "$FUN_FRONTEND_COMMAND" ]
	then
		echo "export FUN_FRONTEND_COMMAND=\"APP=fun-frontend yarn start --host\"" >> /home/$USER/.bashrc
	else
		echo "export FUN_FRONTEND_COMMAND=\"$FUN_FRONTEND_COMMAND\"" >> /home/$USER/.bashrc
	fi

	# FileBrowser environment variables

	if [ -z "$FILEBROWSER_PORT" ]
	then
		echo 'export FILEBROWSER_PORT=50002' >> /home/$USER/.bashrc
	else
		echo "export FILEBROWSER_PORT=$FILEBROWSER_PORT" >> /home/$USER/.bashrc
	fi
	echo 'export VITE_FILEBROWSER_PORT=$FILEBROWSER_PORT' >> /home/$USER/.bashrc

	if [ -z "$FILEBROWSER_COMMAND" ]
	then
		echo "export FILEBROWSER_COMMAND=\"APP=filebrowser filebrowser --address=0.0.0.0 -p \$FILEBROWSER_PORT -r ../shared\"" >> /home/$USER/.bashrc
	else
		echo "export FILEBROWSER_COMMAND=\"$FILEBROWSER_COMMAND\"" >> /home/$USER/.bashrc
	fi

	# Funttastic Client server environment variables

	echo "export FUN_CLIENT_REPOSITORY_URL=\"$FUN_CLIENT_REPOSITORY_URL\"" >> /home/$USER/.bashrc
	echo "export FUN_CLIENT_REPOSITORY_BRANCH=\"$FUN_CLIENT_REPOSITORY_BRANCH\"" >> /home/$USER/.bashrc

	if [ -z "$FUN_CLIENT_PORT" ]
	then
		echo 'export FUN_CLIENT_PORT=50001' >> /home/$USER/.bashrc
	else
		echo "export FUN_CLIENT_PORT=$FUN_CLIENT_PORT" >> /home/$USER/.bashrc
	fi

	if [ -z "$FUN_CLIENT_COMMAND" ]
	then
		echo "export FUN_CLIENT_COMMAND=\"APP=fun-client python app.py\"" >> /home/$USER/.bashrc
	else
		echo "export FUN_CLIENT_COMMAND=\"$FUN_CLIENT_COMMAND\"" >> /home/$USER/.bashrc
	fi

	# HB Gateway environment variables

	echo "export HB_GATEWAY_REPOSITORY_URL=\"$HB_GATEWAY_REPOSITORY_URL\"" >> /home/$USER/.bashrc
	echo "export HB_GATEWAY_REPOSITORY_BRANCH=\"$HB_GATEWAY_REPOSITORY_BRANCH\"" >> /home/$USER/.bashrc

	if [ -z "$HB_GATEWAY_PORT" ]
	then
		echo 'export HB_GATEWAY_PORT=15888' >> /home/$USER/.bashrc
	else
		echo "export HB_GATEWAY_PORT=$HB_GATEWAY_PORT" >> /home/$USER/.bashrc
	fi

	if [ -z "$HB_GATEWAY_COMMAND" ]
	then
		echo "export HB_GATEWAY_COMMAND=\"APP=hb-gateway yarn start\"" >> /home/$USER/.bashrc
	else
		echo "export HB_GATEWAY_COMMAND=\"$HB_GATEWAY_COMMAND\"" >> /home/$USER/.bashrc
	fi

	# HB Client environment variables

	echo "export HB_CLIENT_REPOSITORY_URL=\"$HB_CLIENT_REPOSITORY_URL\"" >> /home/$USER/.bashrc
	echo "export HB_CLIENT_REPOSITORY_BRANCH=\"$HB_CLIENT_REPOSITORY_BRANCH\"" >> /home/$USER/.bashrc

	if [ -z "$HB_CLIENT_COMMAND" ]
	then
		echo "export HB_CLIENT_COMMAND=\"APP=hb-client python bin/hummingbot_quickstart.py; exit\"" >> /home/$USER/.bashrc
	else
		echo "export HB_CLIENT_COMMAND=\"$HB_CLIENT_COMMAND\"" >> /home/$USER/.bashrc
	fi

	echo -e "\n" >> /home/$USER/.bashrc

	#--------------------------------------------------

	echo -e "\n" >> /home/$USER/.bashrc

	echo "export DEBIAN_FRONTEND=\"$DEBIAN_FRONTEND\"" >> /home/$USER/.bashrc
	echo "export TZ=\"$TZ\"" >> /home/$USER/.bashrc
	echo "export AUTO_SIGN_IN=\"$AUTO_SIGN_IN\"" >> /home/$USER/.bashrc
	echo "export LOCK_APT=\"$LOCK_APT\"" >> /home/$USER/.bashrc

	echo -e "\n" >> /home/$USER/.bashrc

  #--------------------------------------------------

	unlink /usr/bin/pip
	ln -s /usr/bin/python3 /usr/bin/python
	ln -s /usr/bin/pip3 /usr/bin/pip

	#--------------------------------------------------

	cat <<'NGINX' > "/etc/nginx/sites-available/funttastic"
NGINX

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

	echo "export ARCHITECTURE=$ARCHITECTURE" >> ~/.bashrc
	echo "export OS=$OS" >> ~/.bashrc
	echo "export FILE_EXTENSION=$FILE_EXTENSION" >> ~/.bashrc
	echo "export IS_RASPBERRY=$IS_RASPBERRY" >> ~/.bashrc

	if [ "$ARCHITECTURE" == "aarch64" ]
	then
		echo "export ARCHITECTURE_SUFFIX=\"-$ARCHITECTURE\"" >> ~/.bashrc
		MINICONDA_VERSION="Mambaforge-$(uname)-$(uname -m).sh"
		MINICONDA_URL="https://github.com/conda-forge/miniforge/releases/latest/download/$MINICONDA_VERSION"
		ln -s ~/mambaforge ~/miniconda3
	else
		MINICONDA_VERSION="Miniconda3-py38_4.10.3-$OS-$ARCHITECTURE.$FILE_EXTENSION"
		MINICONDA_URL="https://repo.anaconda.com/miniconda/$MINICONDA_VERSION"
	fi

	curl -L "$MINICONDA_URL" -o "~/miniconda.$MINICONDA_EXTENSION"
	/bin/bash "~/miniconda.$MINICONDA_EXTENSION" -b
	rm "~/miniconda.$MINICONDA_EXTENSION"

	echo 'export PATH=~/miniconda3/bin:$PATH' >> ~/.bashrc
	source ~/.bashrc

	conda update -n base -c conda-forge conda -y
	conda clean -tipy

	echo "export MINICONDA_VERSION=$MINICONDA_VERSION" >> ~/.bashrc
	echo "export MINICONDA_URL=$MINICONDA_URL" >> ~/.bashrc

	conda init --all

	#--------------------------------------------------

	source ~/.bashrc

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

	rm -rf ~/.cache
}

install() {
	set -ex

	cd ~

	source ~/.bashrc

	#--------------------------------------------------

	mkdir -p ~/funttastic/client
	cd ~/funttastic/client

	git clone -b $FUN_CLIENT_REPOSITORY_BRANCH $FUN_CLIENT_REPOSITORY_URL .

	conda env create -f environment.yml

	conda activate funttastic

	cp resources/configuration/production.example.yml resources/configuration/production.yml
	cp -a resources/strategies/templates/. resources/strategies

	#--------------------------------------------------

	source ~/.bashrc

	mkdir -p ~/funttastic/frontend
	cd ~/funttastic/frontend

	git clone -b $FUN_FRONTEND_REPOSITORY_BRANCH $FUN_FRONTEND_REPOSITORY_URL .

	yarn install

	#--------------------------------------------------

	curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash
	rm -f get.sh

	mkdir -p ~/filebrowser/branding/img
	cd ~/filebrowser

	filebrowser config init
	filebrowser config set --branding.name "Funttastic"
	filebrowser config set --branding.theme "dark"
	filebrowser config set --branding.files ~/filebrowser/branding
	filebrowser config set --port $FILEBROWSER_PORT
	filebrowser config set --baseurl /

	cp ~/funttastic/frontend/resources/assets/funttastic/logo/logo.svg branding/img/logo.svg

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

	source ~/.bashrc

	mkdir -p ~/hummingbot/gateway
	cd ~/hummingbot/gateway

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

	#--------------------------------------------------

	source ~/.bashrc

	mkdir -p ~/hummingbot/client
	cd ~/hummingbot/client

	git clone -b $HB_CLIENT_REPOSITORY_BRANCH $HB_CLIENT_REPOSITORY_URL .

	MINICONDA_ENVIRONMENT=$(head -1 setup/environment.yml | cut -d' ' -f2)
	if [ -z "$MINICONDA_ENVIRONMENT" ]
	then
		echo "The MINICONDA_ENVIRONMENT environment variable could not be defined."
		exit 1
	fi
	echo "export MINICONDA_ENVIRONMENT=$MINICONDA_ENVIRONMENT" >> ~/.bashrc

	conda env create -f setup/environment.yml
	conda clean -tipy
	rm -rf ~/.cache

	echo "source ~/miniconda3/etc/profile.d/conda.sh && conda activate $MINICONDA_ENVIRONMENT" >> ~/.bashrc
	~/miniconda3/envs/$MINICONDA_ENVIRONMENT/bin/python3 setup.py build_ext --inplace -j 8
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

	source ~/.bashrc

	conda activate funttastic

	sed -i -e "/server:/,/port: [0-9]*/ s/port: [0-9]*/port: $FUN_CLIENT_PORT/" ~/funttastic/client/resources/configuration/production.yml
	sed -i -e '/logging:/,/use_telegram:/ s/use_telegram:.*/use_telegram: false/' -e '/telegram:/,/enabled:/ s/enabled:.*/enabled: false/' -e '/telegram:/,/listen_commands:/ s/listen_commands:.*/listen_commands: false/' ~/funttastic/client/resources/configuration/production.yml
	sed -i -e '/telegram:/,/enabled:/ s/enabled:.*/enabled: false/' -e '/telegram:/,/listen_commands:/ s/listen_commands:.*/listen_commands: false/' ~/funttastic/client/resources/configuration/common.yml

	#--------------------------------------------------

	mkdir -p ~/shared/logs/tmux
  ln -s ~/funttastic/client/resources/logs ~/shared/logs/fun-client
  ln -s ~/hummingbot/gateway/logs ~/shared/logs/hb-gateway
  ln -s ~/hummingbot/client/logs ~/shared/logs/hb-client

  mkdir -p ~/shared/scripts

  cat <<'SCRIPT' > ~/shared/scripts/functions.sh
#!/bin/bash

start_nginx() {
	local session="nginx"

	if [ "$(is_session_running "$session")" = "FALSE" ]; then
		tmux new-session -d -s "$session" \; pipe-pane -o "cat >> ~/shared/logs/tmux/$session.log"

		tmux send-keys -t "$session" "nginx -g \"daemon off;\"" C-m
	fi
}

start_fun_frontend() {
	local session="fun-frontend"

	if [ "$(is_session_running "$session")" = "FALSE" ]; then
		tmux new-session -d -s "$session" \; pipe-pane -o "cat >> ~/shared/logs/tmux/$session.log"

		tmux send-keys -t "$session" "cd ~/funttastic/frontend" C-m
		tmux send-keys -t "$session" "$FUN_FRONTEND_COMMAND" C-m
	fi
}

start_filebrowser() {
	local session="filebrowser"

	if [ "$(is_session_running "$session")" = "FALSE" ]; then
		tmux new-session -d -s "$session" \; pipe-pane -o "cat >> ~/shared/logs/tmux/$session.log"

		tmux send-keys -t "$session" "cd ~/filebrowser" C-m
		tmux send-keys -t "$session" "$FILEBROWSER_COMMAND" C-m
	fi
}

start_fun_client() {
	local password="$1"
	local session="fun-client"

	if [ "$(is_session_running "$session")" = "FALSE" ]; then
		tmux new-session -d -s "$session" \; pipe-pane -o "cat >> ~/shared/logs/tmux/$session.log"

#		tmux set-environment -t "$session" PASSWORD "$password"
#		tmux send-keys -t "$session" "export PASSWORD=\"$(tmux show-environment PASSWORD | cut -d= -f2)\"" C-m
		tmux send-keys -t "$session" "export PASSWORD=\"$password\"" C-m
		tmux send-keys -t "$session" "conda activate funttastic" C-m
		tmux send-keys -t "$session" "cd ~/funttastic/client" C-m
		tmux send-keys -t "$session" "$FUN_CLIENT_COMMAND" C-m
#		tmux set-environment -t "$session" -u PASSWORD
	fi
}

start_hb_gateway() {
	local password="$1"
	local session="hb-gateway"

	if [ "$(is_session_running "$session")" = "FALSE" ]; then
		tmux new-session -d -s "$session" \; pipe-pane -o "cat >> ~/shared/logs/tmux/$session.log"

		tmux set-environment -t "$session" GATEWAY_PASSPHRASE "$password"
		tmux send-keys -t "$session" "export GATEWAY_PASSPHRASE=\$(tmux show-environment -t $session GATEWAY_PASSPHRASE | cut -d= -f2)" C-m
		tmux send-keys -t "$session" "cd ~/hummingbot/gateway" C-m
		tmux send-keys -t "$session" "$HB_GATEWAY_COMMAND" C-m
		tmux set-environment -t "$session" -u GATEWAY_PASSPHRASE
	fi
}

start_hb_client() {
	local session="hb-client"

	if [ "$(is_session_running "$session")" = "FALSE" ]; then
		tmux new-session -d -s "$session" \; pipe-pane -o "cat >> ~/shared/logs/tmux/$session.log"

		tmux send-keys -t "$session" "conda activate hummingbot" C-m
		tmux send-keys -t "$session" "cd ~/hummingbot/client" C-m
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

	source ~/.bashrc

	if [[ -n "$username" && -n "$password"  ]]; then
		credentials=$(authenticate "$username" "$password")
	elif [ -f "~/.temp_credentials" ]; then
		# This condition is only for the first start.

		username=$(grep "username" "~/.temp_credentials" | cut -d'=' -f2)
		password=$(grep "password" "~/.temp_credentials" | cut -d'=' -f2)

		credentials=$(authenticate "$username" "$password")

		if [ -n "$credentials" ]; then
			rm -f ~/.temp_credentials
		fi
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
	local encrypted_message_base64=$(echo "$message" | openssl pkeyutl -encrypt -pubin -inkey ~/.ssh/id_rsa_openssl.pub.pem -pkeyopt rsa_padding_mode:oaep | base64)

	echo "$encrypted_message_base64"
}

decrypt_message() {
	local encrypted_message_base64=$1

	# Decode the Base64 encrypted message and decrypt it directly
	local decrypted_message=$(echo "$encrypted_message_base64" | base64 --decode | openssl pkeyutl -decrypt -inkey ~/.ssh/id_rsa -pkeyopt rsa_padding_mode:oaep)

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

	if [ ! -f "~/.ssh/id_rsa" ] || { [[ -n "$username" ]] && [[ -n "$password" ]]; }; then
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
		~/shared/logs/tmux/fun-frontend.log \
		~/shared/logs/tmux/filebrowser.log \
		~/shared/logs/tmux/fun-client.log \
		~/shared/logs/tmux/hb-gateway.log \
		~/shared/logs/fun-client/all.log \
		~/shared/logs/hb-gateway/* \
		~/shared/logs/hb-client/*
}

quick_deploy_fun_hb_client () {
	set -ex

	local branch="$1"

	cd ~/funttastic/client || { echo "Failed to open the repository folder..."; return 1; }

	unlink ~/funttastic/client/resources

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

	rm -rf ~/funttastic/client/resources

	ln -s ~/shared/funttastic/client/resources ~/funttastic/client/resources

	git stash apply

	cd ~ || return

	set +ex
}

SCRIPT

	chmod +x ~/shared/scripts/functions.sh

	cat <<'SCRIPT' > ~/shared/scripts/initialize.sh
#!/bin/bash

source ~/shared/scripts/functions.sh

SCRIPT

	echo "source ~/shared/scripts/initialize.sh" >> ~/.bashrc

	source ~/.bashrc

	#--------------------------------------------------

	set +x

	source ~/.bashrc

	# Certificates
	#--------------------------------------------------
	mkdir -p ~/shared/common/certificates

	if [ "$USE_VALID_SSL_CERTIFICATES" = "TRUE" ]; then
		certbot --nginx --non-interactive --agree-tos -m $ADMIN_EMAIL -d $DOMAIN
#		certbot certonly --standalone -d $DOMAIN --non-interactive --agree-tos -m $ADMIN_EMAIL

		ln -s "/etc/letsencrypt/live/$DOMAIN/chain.pem" ~/shared/common/certificates/ca_cert.pem
		ln -s "/etc/letsencrypt/live/$DOMAIN/privkey.pem" ~/shared/common/certificates/ca_key.pem
		ln -s "/etc/letsencrypt/live/$DOMAIN/cert.pem" ~/shared/common/certificates/client_cert.pem
		ln -s "/etc/letsencrypt/live/$DOMAIN/privkey.pem" ~/shared/common/certificates/client_key.pem
		ln -s "/etc/letsencrypt/live/$DOMAIN/cert.pem" ~/shared/common/certificates/server_cert.pem
		ln -s "/etc/letsencrypt/live/$DOMAIN/privkey.pem" ~/shared/common/certificates/server_key.pem

		(crontab -l 2>/dev/null; echo "0 0 */30 * * /usr/bin/certbot renew --quiet") | crontab -

		service cron start
  else
  	# For using a self signed certificate
  	conda activate funttastic
		python ~/funttastic/client/resources/scripts/generate_ssl_certificates.py --passphrase $ADMIN_PASSWORD --cert-path ~/shared/common/certificates
  fi

	# HB Client
	conda activate hummingbot
	python ~/funttastic/client/resources/scripts/generate_hb_client_password_verification_file.py -p "$ADMIN_PASSWORD" -d ~/hummingbot/client/conf

	# Fun Client

	# Fun Frontend

	# Filebrowser
	cd ~/filebrowser
	filebrowser users add $ADMIN_USERNAME $ADMIN_PASSWORD --perm.admin
#	filebrowser users update $ADMIN_USERNAME --commands="ls,git,tree,curl,rm,mkdir,pwd,cp,mv,cat,less,find,touch,echo,chmod,chown,df,du,ps,kill"

	mkdir -p ~/.ssh
	chmod 0700 ~/.ssh
	cd ~/.ssh/

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

	echo "# Credentials Section - Begin" >> ~/.bashrc
	echo "export ENCRYPTED_CREDENTIALS=\"$ENCRYPTED_CREDENTIALS_BASE64\"" >> ~/.bashrc
	echo "export NON_ENCRYPTED_CREDENTIALS_SHA256SUM=\"$NON_ENCRYPTED_CREDENTIALS_JSON_SHA256SUM\"" >> ~/.bashrc
	echo "# Credentials Section - End" >> ~/.bashrc

	# Necessary because the CMD instruction does not work with variables of type ARG, only of type ENV
	# We cannot convert the ADMIN_USERNAME and ADMIN_PASSWORD variables to ENV for security reasons
	echo "username=$ADMIN_USERNAME" > ~/.temp_credentials
	echo "password=$ADMIN_PASSWORD" >> ~/.temp_credentials

	if [ ! "$AUTO_SIGN_IN" == "TRUE" ]; then
		rm -f ~/.ssh/id_rsa
		rm -f ~/.ssh/id_rsa_openssl.pem
	fi

  set -x

	#--------------------------------------------------

	mkdir -p \
  		~/shared/common \
  		~/shared/funttastic/client \
  		~/shared/hummingbot/client \
  		~/shared/hummingbot/gateway

	rm -rf ~/funttastic/client/resources/certificates
	rm -rf ~/hummingbot/client/certs
	rm -rf ~/hummingbot/gateway/certs
	ln -s ~/shared/common/certificates ~/funttastic/client/resources/certificates
	ln -s ~/shared/common/certificates ~/hummingbot/gateway/certs
	ln -s ~/shared/common/certificates ~/hummingbot/client/certs

	mv ~/funttastic/client/resources ~/shared/funttastic/client/
	ln -s ~/shared/funttastic/client/resources ~/funttastic/client/resources

	mv ~/hummingbot/gateway/db ~/shared/hummingbot/gateway/
	mv ~/hummingbot/gateway/conf ~/shared/hummingbot/gateway/
	mv ~/hummingbot/gateway/logs ~/shared/hummingbot/gateway/
	ln -s ~/shared/hummingbot/gateway/db ~/hummingbot/gateway/db
	ln -s ~/shared/hummingbot/gateway/conf ~/hummingbot/gateway/conf
	ln -s ~/shared/hummingbot/gateway/logs ~/hummingbot/gateway/logs

	mv ~/hummingbot/client/conf ~/shared/hummingbot/client/
	mv ~/hummingbot/client/logs ~/shared/hummingbot/client/
	mv ~/hummingbot/client/data ~/shared/hummingbot/client/
	mv ~/hummingbot/client/scripts ~/shared/hummingbot/client/
	mv ~/hummingbot/client/pmm_scripts ~/shared/hummingbot/client/
	ln -s ~/shared/hummingbot/client/conf ~/hummingbot/client/conf
	ln -s ~/shared/hummingbot/client/logs ~/hummingbot/client/logs
	ln -s ~/shared/hummingbot/client/data ~/hummingbot/client/data
	ln -s ~/shared/hummingbot/client/scripts ~/hummingbot/client/scripts
	ln -s ~/shared/hummingbot/client/pmm_scripts ~/hummingbot/client/pmm_scripts
}

post_install() {
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

	#--------------------------------------------------

	source ~/.bashrc && start && keep
}
