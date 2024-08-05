FROM ubuntu:latest

ARG DEBIAN_FRONTEND="noninteractive"
ARG TZ="Etc/GMT"

ARG ADMIN_USERNAME="$ADMIN_USERNAME"
ARG ADMIN_PASSWORD="$ADMIN_PASSWORD"
ARG ADMIN_EMAIL="$ADMIN_EMAIL"

ARG DOMAIN="$DOMAIN"
ARG AUTO_SIGN_IN="$AUTO_SIGN_IN"
ARG LOCK_APT="$LOCK_APT"

ARG DEFAULT_BRANCH="${DEFAULT_BRANCH:-production}"

ARG QUICK_START_GUIDE_BRANCH="${QUICK_START_GUIDE_BRANCH:-$DEFAULT_BRANCH}"

ARG FUN_FRONTEND_REPOSITORY_URL="$FUN_FRONTEND_REPOSITORY_URL"
ARG FUN_FRONTEND_REPOSITORY_BRANCH="$FUN_FRONTEND_REPOSITORY_BRANCH"
ARG FUN_FRONTEND_COMMAND="$FUN_FRONTEND_COMMAND"
ARG FUN_FRONTEND_PORT="$FUN_FRONTEND_PORT"

ARG FUN_CLIENT_REPOSITORY_URL="$FUN_CLIENT_REPOSITORY_URL"
ARG FUN_CLIENT_REPOSITORY_BRANCH="$FUN_CLIENT_REPOSITORY_BRANCH"
ARG FUN_CLIENT_COMMAND="$FUN_CLIENT_COMMAND"
ARG FUN_CLIENT_PORT="$FUN_CLIENT_PORT"

ARG HB_GATEWAY_REPOSITORY_URL="$HB_GATEWAY_REPOSITORY_URL"
ARG HB_GATEWAY_REPOSITORY_BRANCH="$HB_GATEWAY_REPOSITORY_BRANCH"
ARG HB_GATEWAY_COMMAND="$HB_GATEWAY_COMMAND"
ARG HB_GATEWAY_PORT="$HB_GATEWAY_PORT"

ARG HB_CLIENT_REPOSITORY_URL="$HB_CLIENT_REPOSITORY_URL"
ARG HB_CLIENT_REPOSITORY_BRANCH="$HB_CLIENT_REPOSITORY_BRANCH"
ARG HB_CLIENT_COMMAND="$HB_CLIENT_COMMAND"

ARG FILEBROWSER_COMMAND="$FILEBROWSER_COMMAND"
ARG FILEBROWSER_PORT="$FILEBROWSER_PORT"

WORKDIR /root

RUN :> /root/.bashrc

RUN rm /usr/bin/sh && ln -s /bin/bash /usr/bin/sh

RUN <<-EOF
	set -ex

	apt update
	apt install curl -y

  curl -o "/tmp/standalone_install.sh https://raw.githubusercontent.com/funttastic/kujira-quickstart-guide/$QUICK_START_GUIDE_BRANCH/scripts/standalone_install.sh"

  chmod +x /tmp/standalone_install.sh

  source /tmp/standalone_install.sh

  fun_standalone_install \
    --username=$ADMIN_USERNAME \
    --password=$ADMIN_PASSWORD \
    --email=$ADMIN_EMAIL \
    --user=$USER \
    --domain=$DOMAIN \
    --auto-sign-in=$AUTO_SIGN_IN \
    --lock-apt=$LOCK_APT \
    --fun-frontend-repository-url=$FUN_FRONTEND_REPOSITORY_URL \
    --fun-frontend-repository-branch=$FUN_FRONTEND_REPOSITORY_BRANCH \
    --fun-frontend-command=$FUN_FRONTEND_COMMAND \
    --fun-frontend-port=$FUN_FRONTEND_PORT \
    --fun-client-repository-url=$FUN_CLIENT_REPOSITORY_URL \
    --fun-client-repository-branch=$FUN_CLIENT_REPOSITORY_BRANCH \
    --fun-client-command=$FUN_CLIENT_COMMAND \
    --fun-client-port=$FUN_CLIENT_PORT \
    --hb-gateway-repository-url=$HB_GATEWAY_REPOSITORY_URL \
    --hb-gateway-repository-branch=$HB_GATEWAY_REPOSITORY_BRANCH \
    --hb-gateway-command=$HB_GATEWAY_COMMAND \
    --hb-gateway-port=$HB_GATEWAY_PORT \
    --hb-client-repository-url=$HB_CLIENT_REPOSITORY_URL \
    --hb-client-repository-branch=$HB_CLIENT_REPOSITORY_BRANCH \
    --hb-client-command=$HB_CLIENT_COMMAND \
    --filebrowser-command=$FILEBROWSER_COMMAND \
    --filebrowser-port=$FILEBROWSER_PORT

  export IS_FIRST_RUN=TRUE

	set +ex
EOF

EXPOSE 80
EXPOSE 443

ENTRYPOINT ["/root/shared/scripts/initialize.sh"]

CMD ["start_and_keep"]
