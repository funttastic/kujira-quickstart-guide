#!/bin/bash

CUSTOMIZE=$1
USER=$(whoami)
GROUP=$(id -gn)
TAG="latest"
CHOICE=""
MIN_PASSPHRASE_LENGTH=4
ENTRYPOINT="/bin/bash"
NETWORK="host"
FUN_CLIENT_APP_PATH_PREFIX="/root/funttastic/client"
HB_GATEWAY_APP_PATH_PREFIX="/root/hummingbot/gateway"
HB_CLIENT_APP_PATH_PREFIX="/root/hummingbot/client"
OUTPUT_SUPPRESSION_MODE="stdout+stderr"
OUTPUT_SUPPRESSION=""

if [ "$OUTPUT_SUPPRESSION_MODE" == "stdout+stderr" ]
  then
#  OUTPUT_SUPPRESSION="&> /dev/null"
  OUTPUT_SUPPRESSION="> /dev/null 2>&1"
elif [ "$OUTPUT_SUPPRESSION_MODE" == "stdout" ]
  then
  OUTPUT_SUPPRESSION="> /dev/null"
elif [ "$OUTPUT_SUPPRESSION_MODE" == "stderr" ]
  then
  OUTPUT_SUPPRESSION="2> /dev/null"
fi

generate_passphrase() {
    local length=$1
    local charset="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    local passphrase=""
    local charset_length=${#charset}
    local max_random=$((32768 - 32768 % charset_length))

    for ((i = 0; i < length; i++)); do
        while (( (random_index=RANDOM) >= max_random )); do :; done
        random_index=$((random_index % charset_length))
        passphrase="${passphrase}${charset:$random_index:1}"
    done

    echo "$passphrase"
}

prompt_proceed () {
  RESPONSE=""
  read -rp "   Do you want to proceed? [Y/n] >>> " RESPONSE
  if [[ "$RESPONSE" == "Y" || "$RESPONSE" == "y" || "$RESPONSE" == "" ]]
  then
    PROCEED="Y"
  fi
}

default_values_info () {
  echo
  echo "ℹ️  Press [ENTER] for default values:"
  echo
}

pre_installation_fun_client () {
  clear
  echo
  echo
  echo "   ==============    FUNTTASTIC CLIENT INSTALLATION SETTINGS    ============="
  echo

  default_values_info

  # Customize the image to be used?
  RESPONSE=$IMAGE_NAME
  if [ "$RESPONSE" == "" ]; then
    echo
    read -rp "   Enter a name for your new image you want to use (default = \"fun-kuji-hb\") >>> " RESPONSE
  fi
  echo
  if [ "$RESPONSE" == "" ]
  then
    IMAGE_NAME="fun-kuji-hb"
  else
    IMAGE_NAME="$RESPONSE"
  fi

  # Create a new image?
  RESPONSE="$BUILD_CACHE"
  if [ "$RESPONSE" == "" ]
  then
    echo
    read -rp "   Do you want to use an existing image (\"y/N\") >>> " RESPONSE
  fi
  if [[ "$RESPONSE" == "N" || "$RESPONSE" == "n" || "$RESPONSE" == "" ]]
  then
    echo
    echo "      A new image will be created..."

    BUILD_CACHE="--no-cache"
  else
    BUILD_CACHE=""
  fi

  # Create a new container?
  RESPONSE="$CONTAINER_NAME"
  if [ "$RESPONSE" == "" ]
  then
    echo
    read -rp "   Enter a name for your new instance\/container (default = \"fun-kuji-hb\") >>> " RESPONSE
  fi
  if [ "$RESPONSE" == "" ]
  then
    CONTAINER_NAME="fun-kuji-hb"
  else
    CONTAINER_NAME=$RESPONSE
  fi

  # Prompt the user for the passphrase to encrypt the certificates
  while true; do
      echo
      read -s -rp "   Enter a passphrase to encrypt the certificates with at least $MIN_PASSPHRASE_LENGTH characters >>> " DEFINED_PASSPHRASE
      if [ -z "$DEFINED_PASSPHRASE" ] || [ ${#DEFINED_PASSPHRASE} -lt "$MIN_PASSPHRASE_LENGTH" ]; then
          echo
          echo
          echo "      Weak passphrase, please try again."
      else
          echo
          break
      fi
  done

  # Exposed port?
  RESPONSE="$FUN_CLIENT_PORT"
  if [ "$RESPONSE" == "" ]
  then
    echo
    read -rp "   Enter a port to expose the Funttastic Client from the instance (default = \"50001\") >>> " RESPONSE
  fi

  if [ "$RESPONSE" == "" ]
  then
    FUN_CLIENT_PORT=50001
  else
    FUN_CLIENT_PORT=$RESPONSE
  fi

  RESPONSE="$FUN_CLIENT_REPOSITORY_URL"
  if [ "$RESPONSE" == "" ]
  then
    echo
    read -rp "   Enter the url from the repository to be cloned
   (default = \"https://github.com/funttastic/fun-hb-client.git\") >>> " RESPONSE
  fi
  if [ "$RESPONSE" == "" ]
  then
    FUN_CLIENT_REPOSITORY_URL="https://github.com/funttastic/fun-hb-client.git"
  else
    FUN_CLIENT_REPOSITORY_URL="$RESPONSE"
  fi

  RESPONSE="$FUN_CLIENT_REPOSITORY_BRANCH"
  if [ "$RESPONSE" == "" ]
  then
    echo
    read -rp "   Enter the branch from the repository to be cloned (default = \"community\") >>> " RESPONSE
  fi
  if [ "$RESPONSE" == "" ]
  then
    FUN_CLIENT_REPOSITORY_BRANCH="community"
  else
    FUN_CLIENT_REPOSITORY_BRANCH="$RESPONSE"
  fi

  RESPONSE="$FUN_CLIENT_AUTO_START"
  if [ "$RESPONSE" == "" ]
  then
    echo
    read -rp "   Do you want to start the server automatically after installation? (\"Y/n\") >>> " RESPONSE
  fi
  if [[ "$RESPONSE" == "Y" || "$RESPONSE" == "y" || "$RESPONSE" == "Yes" || "$RESPONSE" == "yes" || "$RESPONSE" == "" ]]
  then
    echo
    echo "      The server will start automatically after installation."
    FUN_CLIENT_AUTO_START="TRUE"
  else
    FUN_CLIENT_AUTO_START="FALSE"
  fi

  RESPONSE="$FUN_CLIENT_AUTO_START_EVERY_TIME"
  if [[ "$FUN_CLIENT_AUTO_START" == "TRUE" && "$FUN_CLIENT_AUTO_START_EVERY_TIME" == "" ]]; then
    echo
    read -rp "   Should the Funttastic Client server start automatically every time the container starts?
   If you choose \"No\", you will need to start it manually every time the container starts. (\"Y/n\") >>> " RESPONSE

    if [[ "$RESPONSE" == "Y" || "$RESPONSE" == "y" || "$RESPONSE" == "Yes" || "$RESPONSE" == "yes" || "$RESPONSE" == "" ]]; then
      echo
      echo "      The Funttastic Client server will start automatically every time the container starts."
      FUN_CLIENT_AUTO_START_EVERY_TIME="TRUE"
    else
      FUN_CLIENT_AUTO_START_EVERY_TIME="FALSE"
    fi
  fi
}

pre_installation_hb_client () {
  clear
  echo
  echo
  echo "   ==============   HUMMINGBOT CLIENT INSTALLATION SETTINGS   ============="
  echo

  default_values_info

  RESPONSE="$HB_CLIENT_REPOSITORY_URL"
  if [ "$RESPONSE" == "" ]
  then
    echo
    read -rp "   Enter the url from the repository to be cloned
   (default = \"https://github.com/Team-Kujira/hummingbot.git\") >>> " RESPONSE
  fi
  if [ "$RESPONSE" == "" ]
  then
    HB_CLIENT_REPOSITORY_URL="https://github.com/Team-Kujira/hummingbot.git"
  else
    HB_CLIENT_REPOSITORY_URL="$RESPONSE"
  fi

  RESPONSE="$HB_CLIENT_REPOSITORY_BRANCH"
  if [ "$RESPONSE" == "" ]
  then
    echo
    read -rp "   Enter the branch from the repository to be cloned (default = \"community\") >>> " RESPONSE
  fi
  if [ "$RESPONSE" == "" ]
  then
    HB_CLIENT_REPOSITORY_BRANCH="community"
  else
    HB_CLIENT_REPOSITORY_BRANCH="$RESPONSE"
  fi

  RESPONSE="$HB_CLIENT_AUTO_START"
  if [ "$RESPONSE" == "" ]
  then
    echo
    read -rp "   Do you want to start the app automatically after installation? (\"Y/n\") >>> " RESPONSE
  fi
  if [[ "$RESPONSE" == "Y" || "$RESPONSE" == "y" || "$RESPONSE" == "Yes" || "$RESPONSE" == "yes" || "$RESPONSE" == "" ]]
  then
    echo
    echo "      The app will start automatically after installation."
    HB_CLIENT_AUTO_START="TRUE"
  else
    HB_CLIENT_AUTO_START="FALSE"
  fi
}

pre_installation_hb_gateway () {
  clear
  echo
  echo
  echo "   ==============   HUMMINGBOT GATEWAY INSTALLATION SETTINGS   ============="
  echo

  default_values_info

  # Exposed port?
  RESPONSE="$EXPOSE_HB_GATEWAY_PORT"
  if [ "$RESPONSE" == "" ]
  then
    echo
    read -rp "   Do you want to expose the Gateway port from the instance?
   The recommended option is \"No\", but if you choose \"No\",
   you will not be able to make calls directly to the Gateway. (\"y/N\") >>> " RESPONSE
  fi
  if [[ "$RESPONSE" == "N" || "$RESPONSE" == "n" || "$RESPONSE" == "No" || "$RESPONSE" == "no" || "$RESPONSE" == "" ]]; then
    echo
    echo "      The Gateway port will not be exposed from the instance, only Funttastic Client and
      Hummingbot Client will be able to make calls to it from within the container."
    EXPOSE_HB_GATEWAY_PORT="FALSE"
  else
    EXPOSE_HB_GATEWAY_PORT="TRUE"

    RESPONSE="$HB_GATEWAY_PORT"
    if [ "$RESPONSE" == "" ]
    then
      echo
      read -rp "   Enter a port to expose the Hummingbot Gateway from the instance (default = \"15888\") >>> " RESPONSE
    fi
    if [ "$RESPONSE" == "" ]
    then
      HB_GATEWAY_PORT=15888
    else
      HB_GATEWAY_PORT=$RESPONSE
    fi
  fi

  RESPONSE="$HB_GATEWAY_REPOSITORY_URL"
  if [ "$RESPONSE" == "" ]
  then
    echo
    read -rp "   Enter the url from the repository to be cloned
   (default = \"https://github.com/Team-Kujira/gateway.git\") >>> " RESPONSE
  fi
  if [ "$RESPONSE" == "" ]
  then
    HB_GATEWAY_REPOSITORY_URL="https://github.com/Team-Kujira/gateway.git"
  else
    HB_GATEWAY_REPOSITORY_URL="$RESPONSE"
  fi

  RESPONSE="$HB_GATEWAY_REPOSITORY_BRANCH"
  if [ "$RESPONSE" == "" ]
  then
    echo
    read -rp "   Enter the branch from the repository to be cloned (default = \"community\") >>> " RESPONSE
  fi
  if [ "$RESPONSE" == "" ]
  then
    HB_GATEWAY_REPOSITORY_BRANCH="community"
  else
    HB_GATEWAY_REPOSITORY_BRANCH="$RESPONSE"
  fi

  RESPONSE="$HB_GATEWAY_AUTO_START"
  if [ "$RESPONSE" == "" ]
  then
    echo
    read -rp "   Do you want to start the server automatically after installation? (\"Y/n\") >>> " RESPONSE
  fi

  if [[ "$RESPONSE" == "Y" || "$RESPONSE" == "y" || "$RESPONSE" == "Yes" || "$RESPONSE" == "yes" || "$RESPONSE" == "" ]]
  then
    echo
    echo "      The server will start automatically after installation."
    HB_GATEWAY_AUTO_START="TRUE"
  else
    HB_GATEWAY_AUTO_START="FALSE"
  fi

  RESPONSE="$HB_GATEWAY_AUTO_START_EVERY_TIME"
  if [[ "$HB_GATEWAY_AUTO_START" == "TRUE" && "$HB_GATEWAY_AUTO_START_EVERY_TIME" == "" ]]
  then
    echo
    read -rp "   Should the Gateway server start automatically every time the container starts?
   If you choose \"No\", you will need to start it manually every time the container starts. (\"Y/n\") >>> " RESPONSE

    if [[ "$RESPONSE" == "Y" || "$RESPONSE" == "y" || "$RESPONSE" == "Yes" || "$RESPONSE" == "yes" || "$RESPONSE" == "" ]]
  then
    echo
    echo "      The Gateway server will start automatically every time the container starts."
    HB_GATEWAY_AUTO_START_EVERY_TIME="TRUE"
  else
    HB_GATEWAY_AUTO_START_EVERY_TIME="FALSE"
  fi
  fi
}

pre_installation_lock_apt () {
  clear
  echo
  echo
  echo "   ======================  LOCK ADDING NEW PACKAGES   ======================"
  echo

  default_values_info

  RESPONSE="$LOCK_APT"
  if [ "$RESPONSE" == "" ]
  then
    echo
    read -rp "   Do you want to eliminate the possibility of installing new packages inside the
   container after its creation? (\"y/N\") >>> " RESPONSE
  fi
  if [[ "$RESPONSE" == "N" || "$RESPONSE" == "n" || "$RESPONSE" == "No" || "$RESPONSE" == "no" || "$RESPONSE" == "" ]]
  then
    echo
    echo "      The installation of new packages will be allowed."
    LOCK_APT="FALSE"
    sleep 3
  else
    echo
    echo "      You have chosen to block the addition of new packages."
    LOCK_APT="TRUE"
    sleep 3
  fi
}

clear
echo
echo "   ============================     INSTALLATION OPTIONS     ==========================="
echo
echo "   Do you want to automate the entire process,
   including setting a random passphrase? [Y/n]"

echo
echo "ℹ️  Enter the value [back] to return to the previous question."
echo

read -rp "   [Y/n/back] >>> " RESPONSE
if [[ "$RESPONSE" == "Y" || "$RESPONSE" == "y" || "$RESPONSE" == "" ]]
then
  echo
elif [[ "$RESPONSE" == "back" ]]; then
  clear
  ./install.sh
  exit 0
else
  CUSTOMIZE="--customize"
fi

if [ "$CUSTOMIZE" == "--customize" ]
then
  CHOICE="ALL"
  pre_installation_fun_client
  pre_installation_hb_gateway
  pre_installation_hb_client
  pre_installation_lock_apt
else
  # Default settings to install Funttastic Client, Hummingbot Gateway and Hummingbot Client

  # Funttastic Client Settings
  FUN_CLIENT_PORT=${FUN_CLIENT_PORT:-50001}
  FUN_CLIENT_REPOSITORY_URL=${FUN_CLIENT_REPOSITORY_URL:-"https://github.com/funttastic/fun-hb-client.git"}
  FUN_CLIENT_REPOSITORY_BRANCH=${FUN_CLIENT_REPOSITORY_BRANCH:-"community"}
  FUN_CLIENT_AUTO_START=${FUN_CLIENT_AUTO_START:-"TRUE"}

  # Hummingbot Client Settings
  HB_CLIENT_REPOSITORY_URL=${HB_CLIENT_REPOSITORY_URL:-"https://github.com/Team-Kujira/hummingbot.git"}
  HB_CLIENT_REPOSITORY_BRANCH=${HB_CLIENT_REPOSITORY_BRANCH:-"community"}
  HB_CLIENT_AUTO_START=${HB_CLIENT_AUTO_START:-"TRUE"}

  # Hummingbot Gateway Settings
  HB_GATEWAY_PORT=${HB_GATEWAY_PORT:-15888}
  HB_GATEWAY_REPOSITORY_URL=${HB_GATEWAY_REPOSITORY_URL:-"https://github.com/Team-Kujira/gateway.git"}
  HB_GATEWAY_REPOSITORY_BRANCH=${HB_GATEWAY_REPOSITORY_BRANCH:-"community"}
  HB_GATEWAY_AUTO_START=${HB_GATEWAY_AUTO_START:-"TRUE"}
  EXPOSE_HB_GATEWAY_PORT=${EXPOSE_HB_GATEWAY_PORT:-"FALSE"}

  # Common Settings
  IMAGE_NAME="fun-kuji-hb"
  CONTAINER_NAME="$IMAGE_NAME"
  BUILD_CACHE=${BUILD_CACHE:-"--no-cache"}
  FUN_FRONTEND_PORT=${FUN_FRONTEND_PORT:-50000}=
  FILEBROWSER_PORT=${FILEBROWSER_PORT:-50002}
  SSH_PUBLIC_KEY="$SSH_PUBLIC_KEY"
  SSH_PRIVATE_KEY="$SSH_PRIVATE_KEY"
  TAG=${TAG:-"latest"}
  ENTRYPOINT=${ENTRYPOINT:-"/bin/bash"}
  LOCK_APT=${LOCK_APT:-"FALSE"}

	RANDOM_PASSPHRASE=$(generate_passphrase 32)
fi

SELECTED_PASSPHRASE=${RANDOM_PASSPHRASE:-$DEFINED_PASSPHRASE}

if [[ "$SSH_PUBLIC_KEY" && "$SSH_PRIVATE_KEY" ]]; then
  FUN_CLIENT_REPOSITORY_URL="git@github.com:funttastic/fun-hb-client.git"
fi

if [ -n "$RANDOM_PASSPHRASE" ]; then
  echo "   +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  echo "   |                                                                 |"
  echo "   |   A new random passphrase will be saved in the file             |"
  echo "   |                                                                 |"
  echo "   |      temporary/random_passphrase.txt                            |"
  echo "   |                                                                 |"
  echo "   |   To access this file, use the FileBrowser at                  |"
  echo "   |      https://localhost:50000/                                   |"
  echo "   |   or                                                            |"
  echo "   |      https://127.0.0.1:50000/                                   |"
  echo "   |                                                                 |"
  echo "   |   Copy the passphrase to a safe location and delete the file.   |"
  echo "   |                                                                 |"
  echo "   +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  echo
fi

docker_create_image () {
  if [ "$FUN_CLIENT_AUTO_START_EVERY_TIME" == "TRUE" ]; then
    FUN_CLIENT_COMMAND="conda activate funttastic && cd $FUN_CLIENT_APP_PATH_PREFIX && python app.py $OUTPUT_SUPPRESSION &"
  fi

  if [ "$HB_GATEWAY_AUTO_START_EVERY_TIME" == "TRUE" ]; then
    HB_GATEWAY_COMMAND="cd $HB_GATEWAY_APP_PATH_PREFIX && yarn start $OUTPUT_SUPPRESSION &"
  fi

   if [ "$HB_CLIENT_AUTO_START_EVERY_TIME" == "TRUE" ]; then
     HB_CLIENT_COMMAND="conda activate hummingbot && cd $HB_CLIENT_APP_PATH_PREFIX && python bin/hummingbot_quickstart.py 2>> ./logs/errors.log"
   fi

  if [ ! "$BUILD_CACHE" == "" ]
  then
    BUILT=$(DOCKER_BUILDKIT=1 docker build \
    --build-arg SSH_PUBLIC_KEY="$SSH_PUBLIC_KEY" \
    --build-arg SSH_PRIVATE_KEY="$SSH_PRIVATE_KEY" \
    --build-arg HB_GATEWAY_PASSPHRASE="$SELECTED_PASSPHRASE" \
    --build-arg RANDOM_PASSPHRASE="$RANDOM_PASSPHRASE" \
    --build-arg FUN_CLIENT_REPOSITORY_URL="$FUN_CLIENT_REPOSITORY_URL" \
    --build-arg FUN_CLIENT_REPOSITORY_BRANCH="$FUN_CLIENT_REPOSITORY_BRANCH" \
    --build-arg HB_CLIENT_REPOSITORY_URL="$HB_CLIENT_REPOSITORY_URL" \
    --build-arg HB_CLIENT_REPOSITORY_BRANCH="$HB_CLIENT_REPOSITORY_BRANCH" \
    --build-arg HB_GATEWAY_REPOSITORY_URL="$HB_GATEWAY_REPOSITORY_URL" \
    --build-arg HB_GATEWAY_REPOSITORY_BRANCH="$HB_GATEWAY_REPOSITORY_BRANCH" \
    --build-arg HOST_USER_GROUP="$GROUP" \
    --build-arg LOCK_APT="$LOCK_APT" \
    --build-arg FUN_CLIENT_COMMAND="$FUN_CLIENT_COMMAND" \
    --build-arg HB_GATEWAY_COMMAND="$HB_GATEWAY_COMMAND" \
    --build-arg HB_CLIENT_COMMAND="$HB_CLIENT_COMMAND" \
    -t "$IMAGE_NAME" -f ./Dockerfile .)
  fi
}

docker_create_container () {
  if [ "$EXPOSE_HB_GATEWAY_PORT" == "TRUE" ]; then
    sed -i "s/#EXPOSE $HB_GATEWAY_PORT/EXPOSE $HB_GATEWAY_PORT/g" Dockerfile
  fi

  $BUILT \
  && docker run \
    -dit \
    --log-opt max-size=10m \
    --log-opt max-file=5 \
    --name "$CONTAINER_NAME" \
    --network "$NETWORK" \
    --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
    -e FUN_CLIENT_RESOURCES_FOLDER="/root/funttastic/client/resources" \
    -e HB_CLIENT_CONF_FOLDER="/root/hummingbot/client/conf" \
    -e HB_CLIENT_LOGS_FOLDER="/root/hummingbot/client/logs" \
    -e HB_CLIENT_DATA_FOLDER="/root/hummingbot/client/data" \
    -e HB_CLIENT_SCRIPTS_FOLDER="/root/hummingbot/client/scripts" \
    -e HB_CLIENT_PMM_SCRIPTS_FOLDER="/root/hummingbot/client/pmm_scripts" \
    -e HB_GATEWAY_CONF_FOLDER="/root/hummingbot/gateway/conf" \
    -e HB_GATEWAY_LOGS_FOLDER="/root/hummingbot/gateway/logs" \
    -e FUN_CLIENT_PORT="$FUN_CLIENT_PORT" \
    -e HB_GATEWAY_PORT="$HB_GATEWAY_PORT" \
    --entrypoint="$ENTRYPOINT" \
    "$IMAGE_NAME":$TAG
}

post_installation () {
  if [[ "$FUN_CLIENT_AUTO_START" == "TRUE" && "$FUN_CLIENT_AUTO_START_EVERY_TIME" == "FALSE" ]]; then
    docker exec -it "$FUN_CLIENT_CONTAINER_NAME" /bin/bash -lc "conda activate funttastic && cd $FUN_CLIENT_APP_PATH_PREFIX && python app.py $OUTPUT_SUPPRESSION &"
  fi

  if [[ "$HB_GATEWAY_AUTO_START" == "TRUE" && "$HB_GATEWAY_AUTO_START_EVERY_TIME" == "FALSE" ]]; then
    docker exec -it "$HB_GATEWAY_CONTAINER_NAME" /bin/bash -lc "cd $HB_GATEWAY_APP_PATH_PREFIX && yarn start $OUTPUT_SUPPRESSION &"
  fi

  if [ "$HB_CLIENT_AUTO_START" == "TRUE" ]; then
    docker exec -it "$HB_CLIENT_CONTAINER_NAME" /bin/bash -lc "conda activate hummingbot && cd $HB_CLIENT_APP_PATH_PREFIX && python bin/hummingbot_quickstart.py 2>> ./logs/errors.log"
  fi
}

installation () {
  docker_create_image
  docker_create_container
  post_installation
}

execute_installation () {
  case $CHOICE in
    "ALL")
        echo
        echo "   Installing:"
        echo
        echo "     > Funttasstic Client"
        echo "     > Hummingbot Client"
        echo "     > Hummingbot Gateway"
        echo
        echo "     [i] All in just one container."
        echo

        installation
        ;;
  esac
}

install_docker () {
  if [ "$(command -v docker)" ]; then
    execute_installation
  else
    echo "   Docker is not installed."
    echo "   Installing Docker will require superuser permissions."
    read -rp "   Do you want to continue? [y/N] >>> " RESPONSE
    echo

    if [[ "$RESPONSE" == "Y" || "$RESPONSE" == "y" ]]
    then
        sudo echo
        echo "Docker installation started."
        echo

        case $(uname | tr '[:upper:]' '[:lower:]') in
            linux*)
                OS="Linux"

                # Installation for Debian-based distributions (like Ubuntu)
                if [ -f /etc/debian_version ]; then
                    # Update and install prerequisites
                    sudo apt-get update
                    sudo apt-get install -y ca-certificates curl gnupg
                    sudo install -m 0755 -d /etc/apt/keyrings

                    # Add Docker's official GPG key
                    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
                    sudo chmod a+r /etc/apt/keyrings/docker.gpg

                    # Set up the stable repository
                    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME")" stable | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

                    # Install Docker Engine
                    sudo apt-get update
                    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
                elif [ -f /etc/redhat-release ]; then
                    # Installation for Red Hat-based distributions (like CentOS)
                    sudo yum install -y yum-utils
                    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
                    sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
                else
                    echo "   Unsupported Linux distribution"
                    exit 1
                fi

                sudo groupadd -f docker
                sudo usermod -aG docker "$USER"
                sudo chmod 666 /var/run/docker.sock
                sudo systemctl restart docker
                ;;
            darwin*)
                # Installation of Docker for macOS
                OS="MacOSX"

                curl -L "https://download.docker.com/mac/stable/Docker.dmg" -o /tmp/Docker.dmg
                hdiutil attach /tmp/Docker.dmg
                cp -R /Volumes/Docker/Docker.app /Applications
                hdiutil detach /Volumes/Docker
                ;;
            msys*|cygwin*|mingw*)
                # Installation of Docker for Windows (assuming in an environment like Git Bash)
                OS="Windows"

                echo "   To install Docker on Windows, please download and install manually from: https://hub.docker.com/editions/community/docker-ce-desktop-windows/"
                ;;
            *)
                echo "   Unrecognized operating system"
                exit 1
                ;;
        esac

        echo "Operating System: $OS"
        echo "Architecture: $(uname -m)"

        echo
        echo "Docker installation is finished."
        echo

        execute_installation
    else
      echo
      echo "   Script execution aborted."
      echo
    fi
  fi
}

if [[ "$CUSTOMIZE" == "--customize" &&  ! "$NOT_IMPLEMENTED" ]]
then
  clear

  echo
  echo "ℹ️  Confirm below if the common settings are correct:"
  echo
  printf "%25s %5s\n" "Image:"              	"$IMAGE_NAME"
  printf "%25s %5s\n" "Instance:"        			"$CONTAINER_NAME"
  printf "%25s %5s\n" "Reuse image?:"    		  "$BUILD_CACHE"
  printf "%25s %5s\n" "Version:"              "$TAG"
  printf "%25s %5s\n" "Entrypoint:"    				"$ENTRYPOINT"
  echo

  echo
  echo "ℹ️  Confirm below if the Funttastic Client instance and its folders are correct:"
  echo
  printf "%25s %5s\n" "Repository url:"       "$FUN_CLIENT_REPOSITORY_URL"
  printf "%25s %5s\n" "Repository branch:"    "$FUN_CLIENT_REPOSITORY_BRANCH"
  printf "%25s %4s\n" "Exposed port:"					"$FUN_CLIENT_PORT"
  printf "%25s %3s\n" "Autostart:"    		    "$FUN_CLIENT_AUTO_START"
  echo

  echo
  echo "ℹ️  Confirm below if the Hummingbot Client instance and its folders are correct:"
  echo
  printf "%25s %5s\n" "Repository url:"       "$HB_CLIENT_REPOSITORY_URL"
  printf "%25s %5s\n" "Repository branch:"    "$HB_CLIENT_REPOSITORY_BRANCH"
  printf "%25s %5s\n" "Reuse image?:"    		  "$HB_CLIENT_BUILD_CACHE"
  printf "%25s %3s\n" "Autostart:"    		    "$HB_CLIENT_AUTO_START"
  echo

  echo
  echo "ℹ️  Confirm below if the Hummingbot Gateway instance and its folders are correct:"
  echo
  if [ ! "$EXPOSE_HB_GATEWAY_PORT" == "TRUE" ]; then
    printf "%25s %4s\n" "Exposed port:"		    "$HB_GATEWAY_PORT"
  fi
  printf "%25s %5s\n" "Repository url:"       "$HB_GATEWAY_REPOSITORY_URL"
  printf "%25s %5s\n" "Repository branch:"    "$HB_GATEWAY_REPOSITORY_BRANCH"
  printf "%25s %3s\n" "Autostart:"    		    "$HB_GATEWAY_AUTO_START"
  echo

  prompt_proceed

  if [[ "$PROCEED" == "Y" || "$PROCEED" == "y" ]]
  then
    echo
    install_docker
  else
    echo
    echo "   Installation aborted!"
    echo
  fi
else
  if [ ! "$NOT_IMPLEMENTED" ]; then
    CHOICE="ALL"
    install_docker
  fi
fi
