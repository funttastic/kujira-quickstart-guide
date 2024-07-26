#!/bin/bash

# Usage:
# source standalone_install.sh
#	bash -l standalone_install --username=<username> --password=<password> --auto_sign_in=<auto_sign_in> --lock-apt=<lock_apt> --fun-frontend-repository-url=<fun_frontend_repository_url> --fun-frontend-repository-branch=<fun_frontend_repository_branch> --fun-frontend-command=<fun_frontend_command> --fun-frontend-port=<fun_frontend_port> --fun-client-repository-url=<fun_client_repository_url> --fun-client-repository-branch=<fun_client_repository_branch> --fun-client-command=<fun_client_command> --fun-client-port=<fun_client_port> --hb-gateway-repository-url=<hb_gateway_repository_url> --hb-gateway-repository-branch=<hb_gateway_repository_branch> --hb-gateway-command=<hb_gateway_command> --hb-gateway-port=<hb_gateway_port> --hb-client-repository-url=<hb_client_repository_url> --hb-client-repository-branch=<hb_client_repository_branch> --hb-client-command=<hb_client_command> --filebrowser-command=<filebrowser_command> --filebrowser-port=<filebrowser_port>

# To test it, you can create a docker ubuntu container as following:

#!/bin/bash

#image_name=ubuntu
##image_name=test
#container_name=standalone-fun-kuji-hb
#
##./scripts/utils/destroy-all-containers-and-images.sh
#docker rm -f $container_name
#
#docker run \
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
#docker cp ./scripts/standalone_install.sh $container_name:/tmp/standalone_install.sh
#docker exec -it $container_name chmod +x /tmp/standalone_install.sh
#docker exec -it $container_name chmod 777 /tmp/standalone_install.sh
#docker exec -it $container_name bash -c "source /tmp/standalone_install.sh && fun_standalone_install --username=<username> --password=<password> --auto-sign-in=TRUE --lock-apt=FALSE"


fun_standalone_install() {
	set -ex

	local arguments=$*

	fun_export_variables $arguments

	fun_pre_install $arguments

	sudo -u $USER -i <<USER
		source /home/$USER/.bashrc
		source /tmp/standalone_install.sh
		fun_install $arguments
USER

	fun_post_install $arguments

#	sudo -u $USER -i <<USER
#		fun_start
#USER
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
	adduser --gecos "" --disabled-password --home "/home/$USER" $USER
	set +x
	echo "$USER:$ADMIN_PASSWORD" | chpasswd
	set -x

	cp /etc/skel/.bashrc "/home/$USER"
	chown $USER:$USER "/home/$USER/.bashrc"

	#--------------------------------------------------

	echo -e "\n" >> /home/$USER/.bashrc

	echo "export ADMIN_EMAIL=\"$ADMIN_EMAIL\"" >> /home/$USER/.bashrc
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

	curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash
	rm -f get.sh

	#--------------------------------------------------

	cat <<'NGINX' > "/etc/nginx/sites-available/funttastic"
NGINX
}

fun_install() {
	set -ex

#	local arguments=$@
#	fun_export_variables $arguments

	cd /home/$USER

	sed -i 's/^\([[:space:]]*\[ -z "\$PS1" \] && return\)/#\1/' /home/$USER/.bashrc
	sed -i '/case \$- in/,/esac/s/^/#/' ~/.bashrc

	source /home/$USER/.bashrc

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

	echo "export ARCHITECTURE=$ARCHITECTURE" >> /home/$USER/.bashrc
	echo "export OS=$OS" >> /home/$USER/.bashrc
	echo "export FILE_EXTENSION=$FILE_EXTENSION" >> /home/$USER/.bashrc
	echo "export IS_RASPBERRY=$IS_RASPBERRY" >> /home/$USER/.bashrc
	echo "export MINICONDA_EXTENSION=$MINICONDA_EXTENSION" >> /home/$USER/.bashrc

	if [ "$ARCHITECTURE" == "aarch64" ]
	then
		echo "export ARCHITECTURE_SUFFIX=\"-$ARCHITECTURE\"" >> /home/$USER/.bashrc
		MINICONDA_VERSION="Mambaforge-$(uname)-$(uname -m).sh"
		MINICONDA_URL="https://github.com/conda-forge/miniforge/releases/latest/download/$MINICONDA_VERSION"
		ln -s /home/$USER/mambaforge /home/$USER/miniconda3
	else
		MINICONDA_VERSION="Miniconda3-py38_4.10.3-$OS-$ARCHITECTURE.$FILE_EXTENSION"
		MINICONDA_URL="https://repo.anaconda.com/miniconda/$MINICONDA_VERSION"
	fi

	curl -L "$MINICONDA_URL" -o "/home/$USER/miniconda.$MINICONDA_EXTENSION"
	/bin/bash "/home/$USER/miniconda.$MINICONDA_EXTENSION" -b
	rm "/home/$USER/miniconda.$MINICONDA_EXTENSION"

	echo 'export PATH=/home/$USER/miniconda3/bin:$PATH' >> /home/$USER/.bashrc

	. /home/$USER/.bashrc
	conda update -n base -c conda-forge conda -y
	conda clean -tipy

	echo "export MINICONDA_VERSION=$MINICONDA_VERSION" >> /home/$USER/.bashrc
	echo "export MINICONDA_URL=$MINICONDA_URL" >> /home/$USER/.bashrc

	conda init --all

	#--------------------------------------------------

	source /home/$USER/.bashrc

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

	rm -rf /home/$USER/.cache

	#--------------------------------------------------

	source /home/$USER/.bashrc

	conda create -n certbot python=3.11 -y
	conda activate certbot
	conda install pip -y
	pip install --upgrade pip
	pip install certbot certbot-nginx

	#--------------------------------------------------

	mkdir -p /home/$USER/funttastic/client
	cd /home/$USER/funttastic/client

	git clone --depth 1 --no-single-branch -b $FUN_CLIENT_REPOSITORY_BRANCH $FUN_CLIENT_REPOSITORY_URL .

	conda env create -f environment.yml --solver=classic

	conda activate funttastic

	cp resources/configuration/production.example.yml resources/configuration/production.yml
	cp -a resources/strategies/templates/. resources/strategies

	#--------------------------------------------------

	source /home/$USER/.bashrc

	mkdir -p /home/$USER/funttastic/frontend
	cd /home/$USER/funttastic/frontend

	git clone --depth 1 --no-single-branch -b $FUN_FRONTEND_REPOSITORY_BRANCH $FUN_FRONTEND_REPOSITORY_URL .

	yarn install
	git rm -r --cached .

	#--------------------------------------------------

	#curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash
	#rm -f get.sh

	mkdir -p /home/$USER/filebrowser/branding/img
	cd /home/$USER/filebrowser

	filebrowser config init
	filebrowser config set --branding.name "Funttastic"
	filebrowser config set --branding.theme "dark"
	filebrowser config set --branding.files /home/$USER/filebrowser/branding
	filebrowser config set --port $FILEBROWSER_PORT
	filebrowser config set --baseurl /

	cp /home/$USER/funttastic/frontend/resources/assets/funttastic/logo/logo.svg branding/img/logo.svg

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

	source /home/$USER/.bashrc

	mkdir -p /home/$USER/hummingbot/gateway
	cd /home/$USER/hummingbot/gateway

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

	source /home/$USER/.bashrc

	mkdir -p /home/$USER/hummingbot/client
	cd /home/$USER/hummingbot/client

	git clone --depth 1 --no-single-branch -b $HB_CLIENT_REPOSITORY_BRANCH $HB_CLIENT_REPOSITORY_URL .

	MINICONDA_ENVIRONMENT=$(head -1 setup/environment.yml | cut -d' ' -f2)
	if [ -z "$MINICONDA_ENVIRONMENT" ]
	then
		echo "The MINICONDA_ENVIRONMENT environment variable could not be defined."
		exit 1
	fi
	echo "export MINICONDA_ENVIRONMENT=$MINICONDA_ENVIRONMENT" >> /home/$USER/.bashrc

	conda env create -f setup/environment.yml --solver=classic
	conda clean -tipy
	rm -rf /home/$USER/.cache

	echo "source /home/$USER/miniconda3/etc/profile.d/conda.sh && conda activate $MINICONDA_ENVIRONMENT" >> /home/$USER/.bashrc
	/home/$USER/miniconda3/envs/$MINICONDA_ENVIRONMENT/bin/python3 setup.py build_ext --inplace -j 8
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

	source /home/$USER/.bashrc

	conda activate funttastic
	cd /home/user/funttastic/client
	pip install -r requirements.txt

	sed -i -e "/server:/,/port: [0-9]*/ s/port: [0-9]*/port: $FUN_CLIENT_PORT/" /home/$USER/funttastic/client/resources/configuration/production.yml
	sed -i -e '/logging:/,/use_telegram:/ s/use_telegram:.*/use_telegram: false/' -e '/telegram:/,/enabled:/ s/enabled:.*/enabled: false/' -e '/telegram:/,/listen_commands:/ s/listen_commands:.*/listen_commands: false/' /home/$USER/funttastic/client/resources/configuration/production.yml
	sed -i -e '/telegram:/,/enabled:/ s/enabled:.*/enabled: false/' -e '/telegram:/,/listen_commands:/ s/listen_commands:.*/listen_commands: false/' /home/$USER/funttastic/client/resources/configuration/common.yml

	#--------------------------------------------------

	mkdir -p /home/$USER/shared/logs/tmux
  ln -s /home/$USER/funttastic/client/resources/logs /home/$USER/shared/logs/fun-client
  ln -s /home/$USER/hummingbot/gateway/logs /home/$USER/shared/logs/hb-gateway
  ln -s /home/$USER/hummingbot/client/logs /home/$USER/shared/logs/hb-client

  mkdir -p /home/$USER/shared/scripts

  cat <<'SCRIPT' > /home/$USER/shared/scripts/functions.sh
#!/bin/bash

start_nginx() {
	local session="nginx"

	if [ "$(is_session_running "$session")" = "FALSE" ]; then
		tmux new-session -d -s "$session" \; pipe-pane -o "cat >> /home/$USER/shared/logs/tmux/$session.log"

		tmux send-keys -t "$session" "nginx -g \"daemon off;\"" C-m
	fi
}

start_fun_frontend() {
	local session="fun-frontend"

	if [ "$(is_session_running "$session")" = "FALSE" ]; then
		tmux new-session -d -s "$session" \; pipe-pane -o "cat >> /home/$USER/shared/logs/tmux/$session.log"

		tmux send-keys -t "$session" "cd /home/$USER/funttastic/frontend" C-m
		tmux send-keys -t "$session" "$FUN_FRONTEND_COMMAND" C-m
	fi
}

start_filebrowser() {
	local session="filebrowser"

	if [ "$(is_session_running "$session")" = "FALSE" ]; then
		tmux new-session -d -s "$session" \; pipe-pane -o "cat >> /home/$USER/shared/logs/tmux/$session.log"

		tmux send-keys -t "$session" "cd /home/$USER/filebrowser" C-m
		tmux send-keys -t "$session" "$FILEBROWSER_COMMAND" C-m
	fi
}

start_fun_client() {
	local password="$1"
	local session="fun-client"

	if [ "$(is_session_running "$session")" = "FALSE" ]; then
		tmux new-session -d -s "$session" \; pipe-pane -o "cat >> /home/$USER/shared/logs/tmux/$session.log"

#		tmux set-environment -t "$session" PASSWORD "$password"
#		tmux send-keys -t "$session" "export PASSWORD=\"$(tmux show-environment PASSWORD | cut -d= -f2)\"" C-m
		tmux send-keys -t "$session" "export PASSWORD=\"$password\"" C-m
		tmux send-keys -t "$session" "conda activate funttastic" C-m
		tmux send-keys -t "$session" "cd /home/$USER/funttastic/client" C-m
		tmux send-keys -t "$session" "$FUN_CLIENT_COMMAND" ^m
		tmux send-keys -t "$session"  Enter
#		tmux set-environment -t "$session" -u PASSWORD
	fi
}

start_hb_gateway() {
	local password="$1"
	local session="hb-gateway"

	if [ "$(is_session_running "$session")" = "FALSE" ]; then
		tmux new-session -d -s "$session" \; pipe-pane -o "cat >> /home/$USER/shared/logs/tmux/$session.log"

#		tmux set-environment -t "$session" GATEWAY_PASSPHRASE "$password"
#		tmux send-keys -t "$session" "export GATEWAY_PASSPHRASE=\"$(tmux show-environment GATEWAY_PASSPHRASE | cut -d= -f2)\"" C-m
		tmux send-keys -t "$session" "export GATEWAY_PASSPHRASE=\"$password\"" C-m
		tmux send-keys -t "$session" "cd /home/$USER/hummingbot/gateway" C-m
		tmux send-keys -t "$session" "$HB_GATEWAY_COMMAND" C-m
		tmux set-environment -t "$session" -u GATEWAY_PASSPHRASE
	fi
}

start_hb_client() {
	local session="hb-client"

	if [ "$(is_session_running "$session")" = "FALSE" ]; then
		tmux new-session -d -s "$session" \; pipe-pane -o "cat >> /home/$USER/shared/logs/tmux/$session.log"

		tmux send-keys -t "$session" "conda activate hummingbot" C-m
		tmux send-keys -t "$session" "cd /home/$USER/hummingbot/client" C-m
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

	source /home/$USER/.bashrc

	if [[ -n "$username" && -n "$password"  ]]; then
		credentials=$(authenticate "$username" "$password")
	elif [ -f "/home/$USER/.temp_credentials" ]; then
		# This condition is only for the first start.

		username=$(grep "username" "/home/$USER/.temp_credentials" | cut -d'=' -f2)
		password=$(grep "password" "/home/$USER/.temp_credentials" | cut -d'=' -f2)

		credentials=$(authenticate "$username" "$password")

		if [ -n "$credentials" ]; then
			rm -f /home/$USER/.temp_credentials
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
	source /home/$USER/.bashrc

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
	local encrypted_message_base64=$(echo "$message" | openssl pkeyutl -encrypt -pubin -inkey /home/$USER/.ssh/id_rsa_openssl.pub.pem -pkeyopt rsa_padding_mode:oaep | base64)

	echo "$encrypted_message_base64"
}

decrypt_message() {
	local encrypted_message_base64=$1

	# Decode the Base64 encrypted message and decrypt it directly
	local decrypted_message=$(echo "$encrypted_message_base64" | base64 --decode | openssl pkeyutl -decrypt -inkey /home/$USER/.ssh/id_rsa -pkeyopt rsa_padding_mode:oaep)

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

	if [ ! -f "/home/$USER/.ssh/id_rsa" ] || { [[ -n "$username" ]] && [[ -n "$password" ]]; }; then
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
		/home/$USER/shared/logs/tmux/fun-frontend.log \
		/home/$USER/shared/logs/tmux/filebrowser.log \
		/home/$USER/shared/logs/tmux/fun-client.log \
		/home/$USER/shared/logs/tmux/hb-gateway.log \
		/home/$USER/shared/logs/fun-client/all.log \
		/home/$USER/shared/logs/hb-gateway/* \
		/home/$USER/shared/logs/hb-client/*
}

quick_deploy_fun_hb_client () {
	set -ex

	local branch="$1"

	cd /home/$USER/funttastic/client || { echo "Failed to open the repository folder..."; return 1; }

	unlink /home/$USER/funttastic/client/resources

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

	rm -rf /home/$USER/funttastic/client/resources

	ln -s /home/$USER/shared/funttastic/client/resources /home/$USER/funttastic/client/resources

	git stash apply

	cd /home/$USER || return

	set +ex
}

SCRIPT

	chmod +x /home/$USER/shared/scripts/functions.sh

	cat <<'SCRIPT' > /home/$USER/shared/scripts/initialize.sh
#!/bin/bash

source /home/$USER/shared/scripts/functions.sh

SCRIPT

	echo "source /home/$USER/shared/scripts/initialize.sh" >> /home/$USER/.bashrc

	source /home/$USER/.bashrc


	#--------------------------------------------------

	local arguments=$@
	fun_export_variables $arguments

	source /home/$USER/.bashrc

	# Certificates
	#--------------------------------------------------
	mkdir -p /home/$USER/shared/common/certificates/api

  # For using a self signed certificate
	conda activate funttastic
	python /home/$USER/funttastic/client/resources/scripts/generate_ssl_certificates.py --passphrase $ADMIN_PASSWORD --cert-path /home/$USER/shared/common/certificates/api

	# HB Client
	conda activate hummingbot
	python /home/$USER/funttastic/client/resources/scripts/generate_hb_client_password_verification_file.py -p "$ADMIN_PASSWORD" -d /home/$USER/hummingbot/client/conf

	# Fun Client

	# Fun Frontend

	# Filebrowser
	cd /home/$USER/filebrowser
	filebrowser users add $ADMIN_USERNAME $ADMIN_PASSWORD --perm.admin
#	filebrowser users update $ADMIN_USERNAME --commands="ls,git,tree,curl,rm,mkdir,pwd,cp,mv,cat,less,find,touch,echo,chmod,chown,df,du,ps,kill"

	mkdir -p /home/$USER/.ssh
	chmod 0700 /home/$USER/.ssh
	cd /home/$USER/.ssh/

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

	echo "# Credentials Section - Begin" >> /home/$USER/.bashrc
	echo "export ENCRYPTED_CREDENTIALS=\"$ENCRYPTED_CREDENTIALS_BASE64\"" >> /home/$USER/.bashrc
	echo "export NON_ENCRYPTED_CREDENTIALS_SHA256SUM=\"$NON_ENCRYPTED_CREDENTIALS_JSON_SHA256SUM\"" >> /home/$USER/.bashrc
	echo "# Credentials Section - End" >> /home/$USER/.bashrc

	# Necessary because the CMD instruction does not work with variables of type ARG, only of type ENV
	# We cannot convert the ADMIN_USERNAME and ADMIN_PASSWORD variables to ENV for security reasons
	echo "username=$ADMIN_USERNAME" > /home/$USER/.temp_credentials
	echo "password=$ADMIN_PASSWORD" >> /home/$USER/.temp_credentials

	if [ ! "$AUTO_SIGN_IN" == "TRUE" ]; then
		rm -f /home/$USER/.ssh/id_rsa
		rm -f /home/$USER/.ssh/id_rsa_openssl.pem
	fi

  set -x

	#--------------------------------------------------

	mkdir -p \
  		/home/$USER/shared/common \
  		/home/$USER/shared/funttastic/client \
  		/home/$USER/shared/hummingbot/client \
  		/home/$USER/shared/hummingbot/gateway

	rm -rf /home/$USER/funttastic/client/resources/certificates
	rm -rf /home/$USER/hummingbot/client/certs
	rm -rf /home/$USER/hummingbot/gateway/certs
	ln -s /home/$USER/shared/common/certificates/api /home/$USER/funttastic/client/resources/certificates
	ln -s /home/$USER/shared/common/certificates/api /home/$USER/hummingbot/gateway/certs
	ln -s /home/$USER/shared/common/certificates/api /home/$USER/hummingbot/client/certs

	mv /home/$USER/funttastic/client/resources /home/$USER/shared/funttastic/client/
	ln -s /home/$USER/shared/funttastic/client/resources /home/$USER/funttastic/client/resources

	mv /home/$USER/hummingbot/gateway/db /home/$USER/shared/hummingbot/gateway/
	mv /home/$USER/hummingbot/gateway/conf /home/$USER/shared/hummingbot/gateway/
	mv /home/$USER/hummingbot/gateway/logs /home/$USER/shared/hummingbot/gateway/
	ln -s /home/$USER/shared/hummingbot/gateway/db /home/$USER/hummingbot/gateway/db
	ln -s /home/$USER/shared/hummingbot/gateway/conf /home/$USER/hummingbot/gateway/conf
	ln -s /home/$USER/shared/hummingbot/gateway/logs /home/$USER/hummingbot/gateway/logs

	mv /home/$USER/hummingbot/client/conf /home/$USER/shared/hummingbot/client/
	mv /home/$USER/hummingbot/client/logs /home/$USER/shared/hummingbot/client/
	mv /home/$USER/hummingbot/client/data /home/$USER/shared/hummingbot/client/
	mv /home/$USER/hummingbot/client/scripts /home/$USER/shared/hummingbot/client/
	mv /home/$USER/hummingbot/client/pmm_scripts /home/$USER/shared/hummingbot/client/
	ln -s /home/$USER/shared/hummingbot/client/conf /home/$USER/hummingbot/client/conf
	ln -s /home/$USER/shared/hummingbot/client/logs /home/$USER/hummingbot/client/logs
	ln -s /home/$USER/shared/hummingbot/client/data /home/$USER/hummingbot/client/data
	ln -s /home/$USER/shared/hummingbot/client/scripts /home/$USER/hummingbot/client/scripts
	ln -s /home/$USER/shared/hummingbot/client/pmm_scripts /home/$USER/hummingbot/client/pmm_scripts
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
change_user_and_password() {
    local username=$1
    local password=$2
    local current_username="user"
    local current_password=${3:-asdf}

		cd /home/$current_username
    sudo -u $current_username -i env ADMIN_USERNAME=$username ADMIN_PASSWORD=$password ADMIN_CURRENT_PASSWORD=$current_password bash <<'USER'
      source ~/.bashrc

      escaped_admin_username=$(escape_string "${ADMIN_USERNAME}")
      escaped_admin_password=$(escape_string "${ADMIN_PASSWORD}")

      # Changing user password
      echo -e "$ADMIN_CURRENT_PASSWORD\n$escaped_admin_password\n$escaped_admin_password" | passwd

      # Updating credentials
      credentials_json="{\"username\":\"$escaped_admin_username\",\"password\":\"$escaped_admin_password\"}"

      ENCRYPTED_CREDENTIALS_BASE64=$(encrypt_message "$credentials_json")
      NON_ENCRYPTED_CREDENTIALS_JSON_SHA256SUM=$(generate_sha256sum "$credentials_json")
      sed -i "/export ENCRYPTED_CREDENTIALS=/,/^.*\"$/d" ~/.bashrc
      sed -i "/export NON_ENCRYPTED_CREDENTIALS_JSON_SHA256SUM=/,/^.*\"$/d" ~/.bashrc
      echo "export ENCRYPTED_CREDENTIALS=\"$ENCRYPTED_CREDENTIALS_BASE64\"" >> /home/$USER/.bashrc
      echo "export NON_ENCRYPTED_CREDENTIALS_SHA256SUM=\"$NON_ENCRYPTED_CREDENTIALS_JSON_SHA256SUM\"" >> /home/$USER/.bashrc

      # Updating filebrowser credentials
      filebrowser users update user --username $escaped_admin_username --password $escaped_admin_password -d /home/user/filebrowser/filebrowser.db

      # Updating certificates
      conda activate funttastic
      python ~/funttastic/client/resources/scripts/generate_ssl_certificates.py --passphrase $escaped_admin_password --cert-path ~/shared/common/certificates

      # Updating Hummingbot Client credentials
      conda activate hummingbot
      python /home/$USER/funttastic/client/resources/scripts/generate_hb_client_password_verification_file.py -p "$escaped_admin_password" -d /home/$USER/hummingbot/client/conf
USER
}

generate_valid_ssl_certificates() {
  local current_username="user"
  local email=$1
  local password=$2
  local domain=$3

  set -ex

  sed -i "/export ADMIN_EMAIL=/,/^.*\"$/d" /home/$current_username/.bashrc
  sed -i "/export DOMAIN=/,/^.*\"$/d" /home/$current_username/.bashrc
  echo "export ADMIN_EMAIL=\"$email\"" >> /home/$current_username/.bashrc
  echo "export DOMAIN=\"$domain\"" >> /home/$current_username/.bashrc

  sudo -u $current_username -i env current_username=$current_username password=$password bash <<'USER'
    source ~/.bashrc

    set -ex

    conda activate funttastic
    rm -rf /home/$current_username/shared/common/certificates/api
		mkdir -p /home/$current_username/shared/common/certificates/api
    python /home/$current_username/funttastic/client/resources/scripts/generate_ssl_certificates.py --passphrase $password --cert-path /home/$current_username/shared/common/certificates/api

    set +ex
USER

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
	sudo -u user -i <<USER
  	source ~/.bashrc
  	stop
USER
}

start_and_keep() {
	sudo -u user -i <<USER
  	source ~/.bashrc
  	start_and_keep
USER
}

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
}
