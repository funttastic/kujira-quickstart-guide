#!/bin/bash

CUSTOMIZE=$1
USER=$(whoami)
GROUP=$(id -gn)
TAG="latest"
CHOICE=""
MIN_PASSPHRASE_LENGTH=4
ENTRYPOINT=""
NETWORK="host"
LOCAL_HOST_URL_PREFIX="https://localhost"
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

container_exists() {
    # Use the provided container name or the global variable CONTAINER_NAME
    local container_name="${1:-$CONTAINER_NAME}"

    # Getting the list of containers
    local containers
    containers=$(docker ps -a --format "{{.Names}}")

    # Checking if the container exists
    CONTAINER_EXISTS="FALSE"
    for name in $containers; do
        if [ "$name" = "$container_name" ]; then
            CONTAINER_EXISTS="TRUE"
            break
        fi
    done
}

image_exists() {
    # Use the provided image name or the global variable IMAGE_NAME
    local image_name="${1:-$IMAGE_NAME}"

    # Getting the list of images
    local images
    images=$(docker images --format "{{.Repository}}")

    # Checking if the image exists
    IMAGE_EXISTS="FALSE"
    for name in $images; do
        if [ "$name" = "$image_name" ]; then
            IMAGE_EXISTS="TRUE"
            break
        fi
    done
}

invoke_frontend() {
    urls=("$@")

    for url in "${urls[@]}"; do
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            xdg-open "$url"
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            open "$url"
        elif [[ "$OSTYPE" == "cygwin" ]]; then
            cmd.exe /c start "$url"
        elif [[ "$OSTYPE" == "msys" ]]; then
            cmd.exe /c start "$url"
        elif [[ "$OSTYPE" == "win32" ]]; then
            cmd.exe /c start "$url"
        fi
    done
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

pre_installation_define_passphrase () {
  clear
  echo
  echo "   ================    PASSWORD & USERNAME SETTING PROCESS    ==============="
  echo
  echo "   +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  echo "   |                                                                 |"
  echo "   |  ⚠️  It's important that your data remains secure, so we need    |"
  echo "   |     to set a password and an username.                          |"
  echo "   |                                                                 |"
  echo "   |  See the table presented at the end of the password definition  |"
  echo "   |  process, where the password and username will be used.         |"
  echo "   |                                                                 |"
  echo "   +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  echo

  echo "   Let's get started!"

  RESPONSE=$ADMIN_USERNAME
  if [ "$RESPONSE" == "" ]
  then
    echo
    read -rp "   Enter a username you want to use (default = \"admin\") >>> " RESPONSE
  fi
  if [ "$RESPONSE" == "" ]
  then
    ADMIN_USERNAME="admin"
  else
    ADMIN_USERNAME="$RESPONSE"
  fi

  echo
  echo "      ℹ️  The username was defined to \"$ADMIN_USERNAME\""

  while true; do
    echo
    read -s -rp "   Enter a passphrase with at least $MIN_PASSPHRASE_LENGTH characters >>> " ADMIN_PASSWORD
    echo
    if [ -z "$ADMIN_PASSWORD" ] || [ ${#ADMIN_PASSWORD} -lt "$MIN_PASSPHRASE_LENGTH" ]; then
      echo
      echo "      ⚠️  Weak passphrase, please try again."
    else
      while true; do
        echo
        echo "   Please, repeat the passphrase. Type \"see-pass\" to momentarily see the previously entered password."
        echo
        read -s -rp "   >>> " REPEATED_PASSPHRASE
        if [ "$REPEATED_PASSPHRASE" = "see-pass" ]; then
          echo "$ADMIN_PASSWORD"
          sleep 3
          tput cuu 4
          tput ed
        elif [ "$REPEATED_PASSPHRASE" = "$ADMIN_PASSWORD" ]; then
          tput cuu 1
          echo
          echo -e "\r      ✅ Perfect, the passphrase has been set successfully.$(printf ' %.0s' {1..20})"
          break
        else
          tput cuu 1
          echo
          echo -e "\r      ❌ Passphrases do not match, please try again.$(printf ' %.0s' {1..20})"
        fi
      done
      break
    fi
  done

  clear
  echo
  echo "   ================    PASSWORD & USERNAME SETTING PROCESS    ==============="
  echo
  echo "   _________________________________________________________________"
  echo "   | SERVICE OR APPLICATION |  NEEDS PASSWORD  |  NEEDS USERNAME   |"
  echo "   |¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|"
  echo "   |  Funttastic UI         |       Yes        |        Yes        |"
  echo "   |  FileBrowser           |       Yes        |        Yes        |"
  echo "   |  Hummingbot Client     |       Yes        |        No         |"
  echo "   |  Hummingbot Gateway    |       Yes        |        No         |"
  echo "   |  SSL Certificates      |       Yes        |        No         |"
  echo "   |_______________________________________________________________|"

  echo
  read -s -n1 -rp "   Alright, I got it! Press any key to continue >>> "

#  while true; do
#      echo
#      read -s -n1 -rp "   Alright, I got it! Press any key to continue >>> " RESPONSE
#      case "$RESPONSE" in
#          $'\e') ;; # ESC
#          $'\177') ;; # DELETE
#          $'\b') ;; # BACKSPACE
#          *) break ;; # Any other key
#      esac
#  done
}

pre_installation_fun_frontend () {
  echo
#  clear
#  echo
#  echo
#  echo "   ==============    FUNTTASTIC FRONTEND INSTALLATION SETTINGS    ============="
#  echo
#
#  default_values_info
#
#  RESPONSE="$FUN_FRONTEND_PORT"
#  if [ "$RESPONSE" == "" ]
#  then
#    echo
#    read -rp "   Enter a port to expose the Funttastic Frontend from the instance (default = \"50000\") >>> " RESPONSE
#  fi
#
#  if [ "$RESPONSE" == "" ]
#  then
#    FUN_FRONTEND_PORT=50000
#  else
#    FUN_FRONTEND_PORT=$RESPONSE
#  fi
}

pre_installation_filebrowser () {
  echo
#  clear
#  echo
#  echo
#  echo "   ==============    FILEBROWSER INSTALLATION SETTINGS    ============="
#  echo
#
#  default_values_info
#
#  RESPONSE="$FILEBROWSER_PORT"
#  if [ "$RESPONSE" == "" ]
#  then
#    echo
#    read -rp "   Enter a port to expose the FileBrowser from the instance (default = \"50002\") >>> " RESPONSE
#  fi
#
#  if [ "$RESPONSE" == "" ]
#  then
#    FILEBROWSER_PORT=50002
#  else
#    FILEBROWSER_PORT=$RESPONSE
#  fi
}

pre_installation_fun_client () {
  clear
  echo
  echo
  echo "   ==============    FUNTTASTIC CLIENT INSTALLATION SETTINGS    ============="
  echo

  default_values_info

  remove_docker_image() {
    # Docker image name
    local image_name=${1:-$IMAGE_NAME}

    # Stop all containers that are using the image
    docker stop "$(docker ps -a -q --filter ancestor="$image_name")" "$OUTPUT_SUPPRESSION"

    # Remove all containers that are using the image
    docker rm "$(docker ps -a -q --filter ancestor="$image_name")" "$OUTPUT_SUPPRESSION"

    # Remove the image
    docker rmi "$image_name" "$OUTPUT_SUPPRESSION"
  }

  customize_image_name () {
    # Customize the new image name?
    RESPONSE=$IMAGE_NAME
    if [ "$RESPONSE" == "" ]; then
      echo
      read -rp "   Enter a name for your new installation image (default = \"fun-kuji-hb\") >>> " RESPONSE
    fi
    echo

    if [ "$RESPONSE" == "" ]
    then
      IMAGE_NAME="fun-kuji-hb"
    else
      IMAGE_NAME="$RESPONSE"
    fi
  }

  # Create a new image?
  RESPONSE="$BUILD_CACHE"
  if [ "$RESPONSE" == "" ]
  then
    echo
    read -rp "   Do you want to use an image from a previous installation? (\"y/N\") >>> " RESPONSE
  fi
  if [[ "$RESPONSE" == "N" || "$RESPONSE" == "n" || "$RESPONSE" == "" ]]
  then
    echo
    echo "      A new image/installation will be done..."

    BUILD_CACHE="--no-cache"

    customize_image_name

    image_exists "$IMAGE_NAME"

    if [ "$IMAGE_EXISTS" == "TRUE" ]; then
      NO_CONFLICT="FALSE"

      echo "      ⚠️  An installation image with the name \"$IMAGE_NAME\", which you defined
         for this new installation, already exists!"
      echo
      echo "      To ensure that no crashes occur while creating this new image, choose one
      of the options below."
      echo
      echo "      [1] SET A DIFFERENT NAME"
      echo "      [2] REMOVE EXISTING IMAGE"
      echo "      [3] REMOVE ALL IMAGES & CONTAINERS"
      echo

      read -rp "      Enter your choice (1, 2 or 3): " OPTION

      while true; do
          case $OPTION in
              1)
                  customize_image_name
                  image_exists "$IMAGE_NAME"

                  if [ "$IMAGE_EXISTS" == "FALSE" ]; then
                    NO_CONFLICT="TRUE"
                  fi

                  break
                  ;;
              2)
                  remove_docker_image "$IMAGE_NAME"
                  NO_CONFLICT="TRUE"
                  break
                  ;;
              3)
                  ./scripts/utils/destroy-all-containers-and-images.sh "$OUTPUT_SUPPRESSION" &
                  NO_CONFLICT="TRUE"
                  break
                  ;;
              *)
                  echo
                  echo "      ❌ Invalid Input. Enter a your choice (1, 2 or 3)"
                  echo
                  read -rp "      Enter your choice (1, 2 or 3): " OPTION
                  ;;
          esac
      done
    fi

    if [[ "$NO_CONFLICT" == "TRUE" ||  "$IMAGE_EXISTS" == "FALSE" ]]; then
      echo "      The name {$IMAGE_NAME} has been defined for your new image."
    fi
  else
    BUILD_CACHE=""

    RESPONSE=$IMAGE_NAME
    if [ "$RESPONSE" == "" ]; then
      echo
      read -rp "   Which image do you want to reuse? (default = \"fun-kuji-hb\") >>> " RESPONSE
    fi

    if [ "$RESPONSE" == "" ]
    then
      IMAGE_NAME="fun-kuji-hb"
    else
      IMAGE_NAME="$RESPONSE"
    fi

    echo
    echo "      The image {$IMAGE_NAME} will be reused.
      A new image will not be created, just a new container."
  fi

  # Create a new container?
  RESPONSE="$CONTAINER_NAME"
  if [ "$RESPONSE" == "" ]
  then
    echo
    read -rp "   Enter a name for your new instance/container (default = \"fun-kuji-hb\") >>> " RESPONSE
  fi
  if [ "$RESPONSE" == "" ]
  then
    CONTAINER_NAME="fun-kuji-hb"
  else
    CONTAINER_NAME=$RESPONSE
  fi

  echo
  echo "      The name {$CONTAINER_NAME} has been defined for your new instance/container."

  # Expose which port?
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

  if [ "$BUILD_CACHE" == "--no-cache" ]; then
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
    echo "   Should the Funttastic Client server start automatically every time the container starts?
   If you choose \"No\", you will need to start it manually every time the container starts."
    echo
    read -rp "   (\"Y/n\") >>> " RESPONSE

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

  if [ "$BUILD_CACHE" == "--no-cache" ]; then
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
  fi

  RESPONSE="$HB_CLIENT_AUTO_START"
  if [ "$RESPONSE" == "" ]
  then
    echo
    read -rp "   Do you want to start the Hummingbot Client automatically after installation? (\"Y/n\") >>> " RESPONSE
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
    echo "   Do you want to expose the Gateway port from the instance?
   The recommended option is \"No\", but if you choose \"No\",
   you will not be able to make calls directly to the Gateway."
    echo
    read -rp  "   (\"y/N\") >>> " RESPONSE
  fi
  if [[ "$RESPONSE" == "N" || "$RESPONSE" == "n" || "$RESPONSE" == "No" || "$RESPONSE" == "no" || "$RESPONSE" == "" ]]; then
    echo
    echo "   ℹ️  The Gateway port will not be exposed from the instance, only Funttastic Client and
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

  if [ "$BUILD_CACHE" == "--no-cache" ]; then
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
  fi

  RESPONSE="$HB_GATEWAY_AUTO_START"
  if [ "$RESPONSE" == "" ]
  then
    echo
    read -rp "   Do you want to start the Gateway server automatically after installation? (\"Y/n\") >>> " RESPONSE
  fi

  if [[ "$RESPONSE" == "Y" || "$RESPONSE" == "y" || "$RESPONSE" == "Yes" || "$RESPONSE" == "yes" || "$RESPONSE" == "" ]]
  then
    echo
    echo "      The Gateway server will start automatically after installation."
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
  if [ "$BUILD_CACHE" == "" ]; then
    return
  fi

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

pre_installation_define_passphrase

clear
echo
echo "   ============================     INSTALLATION OPTIONS     ==========================="
echo
echo "   Do you want to automate the entire process? [Y/n]"

echo
echo "ℹ️  Enter the value [back] to return to the main menu."
echo

read -rp "   [Y/n/back] >>> " RESPONSE
if [[ "$RESPONSE" == "Y" || "$RESPONSE" == "y" || "$RESPONSE" == "" ]]
then
  echo
elif [[ "$RESPONSE" == "back" ]]; then
  clear
  ./configure
  exit 0
else
  CUSTOMIZE="--customize"
fi

if [ "$CUSTOMIZE" == "--customize" ]
then
  CHOICE="ALL"
  pre_installation_fun_frontend
  pre_installation_filebrowser
  pre_installation_fun_client
  pre_installation_hb_gateway
  pre_installation_hb_client
  pre_installation_lock_apt
else
  # Default settings to install Funttastic Client, Hummingbot Gateway and Hummingbot Client

  # Funttastic Frontend Settings
  FUN_FRONTEND_PORT=${FUN_FRONTEND_PORT:-50000}
  FUN_FRONTEND_URL=${LOCAL_HOST_URL_PREFIX}:${FUN_FRONTEND_PORT}

  # Filebrowser Settings
  FILEBROWSER_PORT=${FILEBROWSER_PORT:-50002}

  # Funttastic Client Settings
  FUN_CLIENT_PORT=${FUN_CLIENT_PORT:-50001}
  FUN_CLIENT_REPOSITORY_URL=${FUN_CLIENT_REPOSITORY_URL:-"https://github.com/funttastic/fun-hb-client.git"}
  FUN_CLIENT_REPOSITORY_BRANCH=${FUN_CLIENT_REPOSITORY_BRANCH:-"community"}
  FUN_CLIENT_AUTO_START=${FUN_CLIENT_AUTO_START:-"TRUE"}
  FUN_CLIENT_AUTO_START_EVERY_TIME=${FUN_CLIENT_AUTO_START_EVERY_TIME:-"TRUE"}

  # Hummingbot Client Settings
  HB_CLIENT_REPOSITORY_URL=${HB_CLIENT_REPOSITORY_URL:-"https://github.com/Team-Kujira/hummingbot.git"}
  HB_CLIENT_REPOSITORY_BRANCH=${HB_CLIENT_REPOSITORY_BRANCH:-"community"}
  HB_CLIENT_AUTO_START=${HB_CLIENT_AUTO_START:-"TRUE"}
  HB_CLIENT_AUTO_START_EVERY_TIME=${HB_CLIENT_AUTO_START_EVERY_TIME:-"TRUE"}


  # Hummingbot Gateway Settings
  HB_GATEWAY_PORT=${HB_GATEWAY_PORT:-15888}
  HB_GATEWAY_REPOSITORY_URL=${HB_GATEWAY_REPOSITORY_URL:-"https://github.com/Team-Kujira/gateway.git"}
  HB_GATEWAY_REPOSITORY_BRANCH=${HB_GATEWAY_REPOSITORY_BRANCH:-"community"}
  HB_GATEWAY_AUTO_START=${HB_GATEWAY_AUTO_START:-"TRUE"}
  HB_GATEWAY_AUTO_START_EVERY_TIME=${HB_GATEWAY_AUTO_START_EVERY_TIME:-"TRUE"}
  EXPOSE_HB_GATEWAY_PORT=${EXPOSE_HB_GATEWAY_PORT:-"FALSE"}

  # Common Settings
  ADMIN_USERNAME=${ADMIN_USERNAME:-"admin"}
  IMAGE_NAME="fun-kuji-hb"
  CONTAINER_NAME="$IMAGE_NAME"
  BUILD_CACHE=${BUILD_CACHE:-"--no-cache"}
  SSH_PUBLIC_KEY="$SSH_PUBLIC_KEY"
  SSH_PRIVATE_KEY="$SSH_PRIVATE_KEY"
  TAG=${TAG:-"latest"}
  ENTRYPOINT=${ENTRYPOINT:-""}
#  ENTRYPOINT=${ENTRYPOINT:-"--entrypoint=\"source /root/.bashrc && start\""}
  LOCK_APT=${LOCK_APT:-"FALSE"}
fi

if [[ "$SSH_PUBLIC_KEY" && "$SSH_PRIVATE_KEY" ]]; then
  FUN_CLIENT_REPOSITORY_URL="git@github.com:funttastic/fun-hb-client.git"
fi

if [ -z "$CUSTOMIZE" ]; then
  echo "   |¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|"
  echo "   |   ℹ️  After Installation,           |"
  echo "   |                                    |"
  echo "   |   to view and edit configuration   |"
  echo "   |   files, use the FileBrowser at    |"
  echo "   |                                    |"
  echo "   |      https://localhost:50002/      |"
  echo "   |   or                               |"
  echo "   |      https://127.0.0.1:50002/      |"
  echo "   |____________________________________|"
  echo
fi


docker_create_image () {
  if [ ! "$BUILD_CACHE" == "" ]
  then
    BUILT=$(DOCKER_BUILDKIT=1 docker build \
    --build-arg ADMIN_USERNAME="$ADMIN_USERNAME" \
    --build-arg ADMIN_PASSWORD="$ADMIN_PASSWORD" \
    --build-arg SSH_PUBLIC_KEY="$SSH_PUBLIC_KEY" \
    --build-arg SSH_PRIVATE_KEY="$SSH_PRIVATE_KEY" \
    --build-arg HB_GATEWAY_PASSPHRASE="$ADMIN_PASSWORD" \
    --build-arg FUN_CLIENT_REPOSITORY_URL="$FUN_CLIENT_REPOSITORY_URL" \
    --build-arg FUN_CLIENT_REPOSITORY_BRANCH="$FUN_CLIENT_REPOSITORY_BRANCH" \
    --build-arg HB_CLIENT_REPOSITORY_URL="$HB_CLIENT_REPOSITORY_URL" \
    --build-arg HB_CLIENT_REPOSITORY_BRANCH="$HB_CLIENT_REPOSITORY_BRANCH" \
    --build-arg HB_GATEWAY_REPOSITORY_URL="$HB_GATEWAY_REPOSITORY_URL" \
    --build-arg HB_GATEWAY_REPOSITORY_BRANCH="$HB_GATEWAY_REPOSITORY_BRANCH" \
    --build-arg HOST_USER_GROUP="$GROUP" \
    --build-arg LOCK_APT="$LOCK_APT" \
    -t "$IMAGE_NAME" -f ./Dockerfile .)
  fi
}

docker_create_container () {
  FUN_FRONTEND_COMMAND="echo $OUTPUT_SUPPRESSION &"
  FILEBROWSER_COMMAND="cd /root && filebrowser -p $FILEBROWSER_PORT -r shared $OUTPUT_SUPPRESSION &"

  if [ "$FUN_CLIENT_AUTO_START_EVERY_TIME" == "TRUE" ]; then
    FUN_CLIENT_COMMAND="conda activate funttastic && cd $FUN_CLIENT_APP_PATH_PREFIX && python app.py $OUTPUT_SUPPRESSION &"
  fi

  if [ "$HB_GATEWAY_AUTO_START_EVERY_TIME" == "TRUE" ]; then
    HB_GATEWAY_COMMAND="cd $HB_GATEWAY_APP_PATH_PREFIX && yarn start $OUTPUT_SUPPRESSION &"
  fi

  if [ "$HB_CLIENT_AUTO_START_EVERY_TIME" == "TRUE" ]; then
    HB_CLIENT_COMMAND="conda activate hummingbot && cd $HB_CLIENT_APP_PATH_PREFIX && python bin/hummingbot_quickstart.py 2>> ./logs/errors.log"
  fi

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
    -e FUN_FRONTEND_PORT="$FUN_FRONTEND_PORT" \
    -e FILEBROWSER_PORT="$FILEBROWSER_PORT" \
    -e FUN_CLIENT_PORT="$FUN_CLIENT_PORT" \
    -e HB_GATEWAY_PORT="$HB_GATEWAY_PORT" \
    -e FUN_FRONTEND_COMMAND="$FUN_FRONTEND_COMMAND" \
    -e FILEBROWSER_COMMAND="$FILEBROWSER_COMMAND" \
    -e FUN_CLIENT_COMMAND="$FUN_CLIENT_COMMAND" \
    -e HB_GATEWAY_COMMAND="$HB_GATEWAY_COMMAND" \
    -e HB_CLIENT_COMMAND="$HB_CLIENT_COMMAND" \
    $ENTRYPOINT \
    "$IMAGE_NAME":$TAG
}

post_installation () {
  invoke_frontend "$FUN_FRONTEND_URL"

  if [[ "$FUN_CLIENT_AUTO_START" == "TRUE" && "$FUN_CLIENT_AUTO_START_EVERY_TIME" == "FALSE" ]]; then
    docker exec -it "$CONTAINER_NAME" /bin/bash -lc "conda activate funttastic && cd $FUN_CLIENT_APP_PATH_PREFIX && python app.py $OUTPUT_SUPPRESSION &"
  fi

  if [[ "$HB_GATEWAY_AUTO_START" == "TRUE" && "$HB_GATEWAY_AUTO_START_EVERY_TIME" == "FALSE" ]]; then
    docker exec -it "$CONTAINER_NAME" /bin/bash -lc "cd $HB_GATEWAY_APP_PATH_PREFIX && yarn start $OUTPUT_SUPPRESSION &"
  fi

  if [ "$HB_CLIENT_AUTO_START" == "TRUE" ]; then
    docker exec -it "$CONTAINER_NAME" /bin/bash -lc "conda activate hummingbot && cd $HB_CLIENT_APP_PATH_PREFIX && python bin/hummingbot_quickstart.py 2>> ./logs/errors.log"
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
        echo "     > Funttastic Client Server"
        echo "     > Funttastic Client Frontend"
        echo "     > Hummingbot Client"
        echo "     > Hummingbot Gateway"
        echo "     > FileBrowser"
        echo
        echo "     ℹ️  All in just one container."
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

  if [ "$BUILD_CACHE" == "--no-cache" ]; then
      REUSE_IMAGE="FALSE"
  else
      REUSE_IMAGE="TRUE"
  fi

  if [ -z "$ENTRYPOINT" ]; then
      DEFINED_ENTRYPOINT="Default"
  else
    DEFINED_ENTRYPOINT="$ENTRYPOINT"
  fi

  echo
  echo "ℹ️  Confirm below if the common settings are correct:"
  echo
  printf "%25s %5s\n" "Image:"              	"$IMAGE_NAME"
  printf "%25s %5s\n" "Instance:"        			"$CONTAINER_NAME"
  printf "%25s %3s\n" "Reuse image:"    		  "$REUSE_IMAGE"
  printf "%25s %5s\n" "Version:"              "$TAG"
  printf "%25s %5s\n" "Entrypoint:"    				"$DEFINED_ENTRYPOINT"
  echo

  echo
  echo "ℹ️  Confirm below if the Funttastic Client instance and its folders are correct:"
  echo
  if [ "$BUILD_CACHE" == "--no-cache" ]; then
    printf "%25s %5s\n" "Repository url:"       "$FUN_CLIENT_REPOSITORY_URL"
    printf "%25s %5s\n" "Repository branch:"    "$FUN_CLIENT_REPOSITORY_BRANCH"
  fi
  printf "%25s %4s\n" "Exposed port:"					"$FUN_CLIENT_PORT"
  printf "%25s %3s\n" "Autostart:"    		    "$FUN_CLIENT_AUTO_START"
  echo

  echo
  echo "ℹ️  Confirm below if the Hummingbot Client instance and its folders are correct:"
  echo
  if [ "$BUILD_CACHE" == "--no-cache" ]; then
    printf "%25s %5s\n" "Repository url:"       "$HB_CLIENT_REPOSITORY_URL"
    printf "%25s %5s\n" "Repository branch:"    "$HB_CLIENT_REPOSITORY_BRANCH"
  fi
  printf "%25s %3s\n" "Autostart:"    		    "$HB_CLIENT_AUTO_START"
  echo

  echo
  echo "ℹ️  Confirm below if the Hummingbot Gateway instance and its folders are correct:"
  echo
  if [ "$BUILD_CACHE" == "--no-cache" ]; then
    printf "%25s %5s\n" "Repository url:"       "$HB_GATEWAY_REPOSITORY_URL"
    printf "%25s %5s\n" "Repository branch:"    "$HB_GATEWAY_REPOSITORY_BRANCH"
  fi
  if [ "$EXPOSE_HB_GATEWAY_PORT" == "TRUE" ]; then
    printf "%25s %4s\n" "Exposed port:"					"$HB_GATEWAY_PORT"
  fi
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
