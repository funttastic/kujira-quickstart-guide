#!/bin/bash

CUSTOMIZE=$1
USER=$(whoami)
GROUP=$(id -gn)
TAG="latest"
CHOICE=0
PASSPHRASE_LENGTH=4
SHARED_FOLDER_SUFFIX="shared"
SHARED_FOLDER=$PWD/$SHARED_FOLDER_SUFFIX
COMMON_FOLDER="$SHARED_FOLDER/common"
ENTRYPOINT="/bin/bash"
NETWORK="host"
CERTS_FOLDER="$COMMON_FOLDER/certificates"

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
  read -p "   Do you want to proceed? [Y/n] >>> " RESPONSE
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

pre_installation_fun_hb_client () {
  echo
  echo
  echo "   ===============    FUNTTASTIC HUMMINGBOT CLIENT INSTALLATION SETUP    ==============="
  echo

  default_values_info

  # Customize the Client image to be used?
  RESPONSE="$FUN_HB_CLIENT_IMAGE_NAME"
  if [ "$RESPONSE" == "" ]
  then
    echo
    read -p "   Enter a Funttastic Hummingbot Client image name you want to use (default = \"fun-hb-client\") >>> " RESPONSE
  fi
  if [ "$RESPONSE" == "" ]
  then
    FUN_HB_CLIENT_IMAGE_NAME="fun-hb-client"
  else
    FUN_HB_CLIENT_IMAGE_NAME="$RESPONSE"
  fi

  # Create a new image?
  RESPONSE="$FUN_HB_CLIENT_BUILD_CACHE"
  if [ "$RESPONSE" == "" ]
  then
    echo
    read -p "   Do you want to use an existing Funttastic Hummingbot Client image (\"y/N\") >>> " RESPONSE
  fi
  if [[ "$RESPONSE" == "N" || "$RESPONSE" == "n" || "$RESPONSE" == "" ]]
  then
    echo
    echo "      A new image will be created..."
    FUN_HB_CLIENT_BUILD_CACHE="--no-cache"
  else
    FUN_HB_CLIENT_BUILD_CACHE=""
  fi

  # Create a new container?
  RESPONSE="$FUN_HB_CLIENT_CONTAINER_NAME"
  if [ "$RESPONSE" == "" ]
  then
    echo
    read -p "   Enter a name for your new Funttastic Hummingbot Client instance (default = \"fun-hb-client\") >>> " RESPONSE
  fi
  if [ "$RESPONSE" == "" ]
  then
    FUN_HB_CLIENT_CONTAINER_NAME="fun-hb-client"
  else
    FUN_HB_CLIENT_CONTAINER_NAME=$RESPONSE
  fi

  # Prompt the user for the passphrase to encrypt the certificates
  while true; do
      echo
      read -s -p "   Enter a passphrase to encrypt the certificates with at least $PASSPHRASE_LENGTH characters >>> " DEFINED_PASSPHRASE
      if [ -z "$DEFINED_PASSPHRASE" ] || [ ${#DEFINED_PASSPHRASE} -lt "$PASSPHRASE_LENGTH" ]; then
          echo
          echo
          echo "      Weak passphrase, please try again."
      else
          echo
          break
      fi
  done

  # Location to save files?
  RESPONSE="$FUN_HB_CLIENT_FOLDER"
  if [ "$RESPONSE" == "" ]
  then
    FUN_HB_CLIENT_FOLDER_SUFFIX="funttastic"
    echo
    read -p "   Enter a folder name where your Funttastic Hummingbot Client files will be saved (default = \"$FUN_HB_CLIENT_FOLDER_SUFFIX\") >>> " RESPONSE
  fi
  if [ "$RESPONSE" == "" ]
  then
    FUN_HB_CLIENT_FOLDER=$SHARED_FOLDER/$FUN_HB_CLIENT_FOLDER_SUFFIX
  elif [[ ${RESPONSE::1} != "/" ]]; then
    FUN_HB_CLIENT_FOLDER=$SHARED_FOLDER/$RESPONSE
  else
    FUN_HB_CLIENT_FOLDER=$RESPONSE
  fi
}

pre_installation_hb_client () {
  echo
  echo
  echo "   ===============   HUMMINGBOT CLIENT INSTALLATION SETUP   ==============="
  echo

  if [ "$CHOICE" == 2 ]; then
    default_values_info
  fi

  RESPONSE="$HB_CLIENT_IMAGE_NAME"
  if [ "$RESPONSE" == "" ]
  then
    echo
    read -p "   Enter a Hummingbot Client image name you want to use (default = \"hb-client\") >>> " RESPONSE
  fi
  if [ "$RESPONSE" == "" ]
  then
    HB_CLIENT_IMAGE_NAME="hb-client"
  else
    HB_CLIENT_IMAGE_NAME="$RESPONSE"
  fi

  # Create a new image?
  RESPONSE="$HB_CLIENT_BUILD_CACHE"
  if [ "$RESPONSE" == "" ]
  then
    echo
    read -p "   Do you want to use an existing Hummingbot Client image (\"y/N\") >>> " RESPONSE
  fi
  if [[ "$RESPONSE" == "N" || "$RESPONSE" == "n" || "$RESPONSE" == "" ]]
  then
    echo
    echo "      A new image will be created..."
    HB_CLIENT_BUILD_CACHE="--no-cache"
  else
    HB_CLIENT_BUILD_CACHE=""
  fi

  # Create a new instance?
  RESPONSE="$HB_CLIENT_CONTAINER_NAME"
  if [ "$RESPONSE" == "" ]
  then
    echo
    read -p "   Enter a name for your new Hummingbot Client instance (default = \"hb-client\") >>> " RESPONSE
  fi
  if [ "$RESPONSE" == "" ]
  then
    HB_CLIENT_CONTAINER_NAME="hb-client"
  else
    HB_CLIENT_CONTAINER_NAME=$RESPONSE
  fi

  # Location to save files?
  RESPONSE="$HB_CLIENT_FOLDER"
  if [ "$RESPONSE" == "" ]
  then
    HB_CLIENT_FOLDER_SUFFIX="client"
    echo
    read -p "   Enter a folder name where your Hummingbot Client files will be saved (default = \"$HB_CLIENT_FOLDER_SUFFIX\") >>> " RESPONSE
  fi
  if [ "$RESPONSE" == "" ]
  then
    HB_CLIENT_FOLDER=$SHARED_FOLDER/"hummingbot"/$HB_CLIENT_FOLDER_SUFFIX
  elif [[ ${RESPONSE::1} != "/" ]]; then
    HB_CLIENT_FOLDER=$SHARED_FOLDER/"hummingbot"/$RESPONSE
  else
    HB_CLIENT_FOLDER=$RESPONSE
  fi

  RESPONSE="$HB_CLIENT_REPOSITORY_URL"
  if [ "$RESPONSE" == "" ]
  then
    echo
    read -p "   Enter the url from the repository to be cloned
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
    read -p "   Enter the branch from the repository to be cloned (default = \"community\") >>> " RESPONSE
  fi
  if [ "$RESPONSE" == "" ]
  then
    HB_CLIENT_REPOSITORY_BRANCH="community"
  else
    HB_CLIENT_REPOSITORY_BRANCH="$RESPONSE"
  fi

  HB_CLIENT_CONF_FOLDER="$HB_CLIENT_FOLDER/conf"
  HB_CLIENT_LOGS_FOLDER="$HB_CLIENT_FOLDER/logs"
  HB_CLIENT_DATA_FOLDER="$HB_CLIENT_FOLDER/data"
  HB_CLIENT_PMM_SCRIPTS_FOLDER="$HB_CLIENT_FOLDER/pmm_scripts"
  HB_CLIENT_SCRIPTS_FOLDER="$HB_CLIENT_FOLDER/scripts"
}

pre_installation_hb_gateway () {
  echo
  echo
  echo "   ===============   HUMMINGBOT GATEWAY INSTALLATION SETUP   ==============="
  echo

  if [ "$CHOICE" == 3 ]; then
    default_values_info
  fi

  RESPONSE="$GATEWAY_IMAGE_NAME"
  if [ "$RESPONSE" == "" ]
  then
    echo
    read -p "   Enter a Hummingbot Gateway image name you want to use (default = \"hb-gateway\") >>> " RESPONSE
  fi
  if [ "$RESPONSE" == "" ]
  then
    GATEWAY_IMAGE_NAME="hb-gateway"
  else
    GATEWAY_IMAGE_NAME="$RESPONSE"
  fi

  # Create a new image?
  RESPONSE="$GATEWAY_BUILD_CACHE"
  if [ "$RESPONSE" == "" ]
  then
    echo
    read -p "   Do you want to use an existing Hummingbot Gateway image (\"y/N\") >>> " RESPONSE
  fi
  if [[ "$RESPONSE" == "N" || "$RESPONSE" == "n" || "$RESPONSE" == "" ]]
  then
    echo
    echo "      A new image will be created..."
    GATEWAY_BUILD_CACHE="--no-cache"
  else
    GATEWAY_BUILD_CACHE=""
  fi

  # Create a new instance?
  RESPONSE="$GATEWAY_CONTAINER_NAME"
  if [ "$RESPONSE" == "" ]
  then
    echo
    read -p "   Enter a name for your new Hummingbot Gateway instance (default = \"hb-gateway\") >>> " RESPONSE
  fi
  if [ "$RESPONSE" == "" ]
  then
    GATEWAY_CONTAINER_NAME="hb-gateway"
  else
    GATEWAY_CONTAINER_NAME=$RESPONSE
  fi

  # Exposed port?
  RESPONSE="$GATEWAY_PORT"
  if [ "$RESPONSE" == "" ]
  then
    echo
    read -p "   Enter a port for expose your new Hummingbot Gateway instance (default = \"15888\") >>> " RESPONSE
  fi
  if [ "$RESPONSE" == "" ]
  then
    GATEWAY_PORT=15888
  else
    GATEWAY_PORT=$RESPONSE
  fi

  # Location to save files?
  RESPONSE="$GATEWAY_FOLDER"
  if [ "$RESPONSE" == "" ]
  then
    GATEWAY_FOLDER_SUFFIX="gateway"
    echo
    read -p "   Enter a folder name where your Hummingbot Gateway files will be saved (default = \"$GATEWAY_FOLDER_SUFFIX\") >>> " RESPONSE
  fi
  if [ "$RESPONSE" == "" ]
  then
    GATEWAY_FOLDER=$SHARED_FOLDER/"hummingbot"/$GATEWAY_FOLDER_SUFFIX
  elif [[ ${RESPONSE::1} != "/" ]]; then
    GATEWAY_FOLDER=$SHARED_FOLDER/"hummingbot"/$RESPONSE
  else
    GATEWAY_FOLDER=$RESPONSE
  fi

  # Executes only if the choice is 3
  if [ "$CHOICE" == 3 ]; then
    # Prompts user for a password for the gateway certificates
    while true; do
        echo
        read -s -p "   Enter a passphrase to encrypt the certificates with at least $PASSPHRASE_LENGTH characters >>> " DEFINED_PASSPHRASE
        if [ -z "$DEFINED_PASSPHRASE" ] || [ ${#DEFINED_PASSPHRASE} -lt "$PASSPHRASE_LENGTH" ]; then
            echo
            echo
            echo "      Weak passphrase, please try again."
        else
            echo
            break
        fi
    done
  fi

  RESPONSE="$GATEWAY_REPOSITORY_URL"
  if [ "$RESPONSE" == "" ]
  then
    echo
    read -p "   Enter the url from the repository to be cloned
   (default = \"https://github.com/Team-Kujira/gateway.git\") >>> " RESPONSE
  fi
  if [ "$RESPONSE" == "" ]
  then
    GATEWAY_REPOSITORY_URL="https://github.com/Team-Kujira/gateway.git"
  else
    GATEWAY_REPOSITORY_URL="$RESPONSE"
  fi

  RESPONSE="$GATEWAY_REPOSITORY_BRANCH"
  if [ "$RESPONSE" == "" ]
  then
    echo
    read -p "   Enter the branch from the repository to be cloned (default = \"community\") >>> " RESPONSE
  fi
  if [ "$RESPONSE" == "" ]
  then
    GATEWAY_REPOSITORY_BRANCH="community"
  else
    GATEWAY_REPOSITORY_BRANCH="$RESPONSE"
  fi

  GATEWAY_CONF_FOLDER="$GATEWAY_FOLDER/conf"
  GATEWAY_LOGS_FOLDER="$GATEWAY_FOLDER/logs"
}

echo
echo "   ===============     WELCOME TO FUNTTASTIC HUMMINGBOT CLIENT SETUP     ==============="
echo

RESPONSE=""
echo "   Do you want to automate the entire process,
   including setting a random passphrase? [Y/n]"

echo
echo "ℹ️  Enter the value [0] to return to the main menu."
echo

read -p "   >>> " RESPONSE
if [[ "$RESPONSE" == "Y" || "$RESPONSE" == "y" || "$RESPONSE" == "" ]]
then
  echo
elif [[ "$RESPONSE" == "0" ]]; then
  clear
  ./configure
  exit 0
else
  CUSTOMIZE="--customize"
fi

if [ "$CUSTOMIZE" == "--customize" ]
then
  echo
  echo "   CHOOSE WHICH INSTALLATION YOU WOULD LIKE TO DO:"
  echo
  echo "   [1] FUNTTASTIC HUMMINGBOT CLIENT"
  echo "   [2] HUMMINGBOT CLIENT"
  echo "   [3] HUMMINGBOT GATEWAY"
  echo "   [4] FUNTTASTIC HUMMINGBOT CLIENT and HUMMINGBOT GATEWAY [RECOMMENDED]"
  echo "   [5] ALL"
  echo
  echo "   [0] RETURN TO MAIN MENU"
  echo
  echo "   For more information about the FUNTTASTIC HUMMINGBOT CLIENT, please visit:"
  echo
  echo "         https://www.funttastic.com/partners/kujira"
  echo

  read -p "   Enter your choice (1-5): " CHOICE

#  if [[ -z $choice || ! $choice =~ ^[1-5]$ ]]; then
#      CHOICE=4
#  fi

  while true; do
    case $CHOICE in
        1|2|3|4|5|0)
            break
            ;;
        *)
            echo "   Invalid Input. Enter a number between 1 and 5."
            ;;
    esac

    read -p "   Enter your choice (1-5): " CHOICE
  done

  case $CHOICE in
      1)
          pre_installation_fun_hb_client
          ;;
      2)
          pre_installation_hb_client
          ;;
      3)
          pre_installation_hb_gateway
          ;;
      4)
          pre_installation_fun_hb_client
          pre_installation_hb_gateway
          ;;
      5)
          pre_installation_fun_hb_client
          pre_installation_hb_gateway
          pre_installation_hb_client
          ;;
      0)
          clear
          ./configure
          ;;
  esac
else
  # Default settings to install Funttastic Hummingbot Client, Hummingbot Gateway and Hummingbot Client

  # Funttastic Hummingbot Client Settings
  FUN_HB_CLIENT_IMAGE_NAME="fun-hb-client"
  FUN_HB_CLIENT_CONTAINER_NAME="fun-hb-client"
  FUN_HB_CLIENT_FOLDER_SUFFIX="funttastic"
  FUN_HB_CLIENT_FOLDER="$SHARED_FOLDER"/"$FUN_HB_CLIENT_FOLDER_SUFFIX"
  FUN_HB_CLIENT_BUILD_CACHE="--no-cache"

  # Hummingbot Client Settings
  HB_CLIENT_IMAGE_NAME=${HB_CLIENT_IMAGE_NAME:-"hb-client"}
  HB_CLIENT_BUILD_CACHE=${HB_CLIENT_BUILD_CACHE:-"--no-cache"}
  HB_CLIENT_CONTAINER_NAME=${HB_CLIENT_CONTAINER_NAME:-"hb-client"}
  HB_CLIENT_FOLDER_SUFFIX=${HB_CLIENT_FOLDER_SUFFIX:-"client"}
  HB_CLIENT_FOLDER=${HB_CLIENT_FOLDER:-$SHARED_FOLDER/"hummingbot"/$HB_CLIENT_FOLDER_SUFFIX}
  HB_CLIENT_REPOSITORY_URL=${HB_CLIENT_REPOSITORY_URL:-"https://github.com/Team-Kujira/hummingbot.git"}
  HB_CLIENT_REPOSITORY_BRANCH=${HB_CLIENT_REPOSITORY_BRANCH:-"community"}
  HB_CLIENT_CONF_FOLDER="$HB_CLIENT_FOLDER/conf"
  HB_CLIENT_LOGS_FOLDER="$HB_CLIENT_FOLDER/logs"
  HB_CLIENT_DATA_FOLDER="$HB_CLIENT_FOLDER/data"
  HB_CLIENT_PMM_SCRIPTS_FOLDER="$HB_CLIENT_FOLDER/pmm_scripts"
  HB_CLIENT_SCRIPTS_FOLDER="$HB_CLIENT_FOLDER/scripts"

  # Hummingbot Gateway Settings
  GATEWAY_IMAGE_NAME=${GATEWAY_IMAGE_NAME:-"hb-gateway"}
  GATEWAY_BUILD_CACHE=${GATEWAY_BUILD_CACHE:-"--no-cache"}
  GATEWAY_CONTAINER_NAME=${GATEWAY_CONTAINER_NAME:-"hb-gateway"}
  GATEWAY_FOLDER_SUFFIX=${GATEWAY_FOLDER_SUFFIX:-"gateway"}
  GATEWAY_FOLDER=${GATEWAY_FOLDER:-$SHARED_FOLDER/"hummingbot"/$GATEWAY_FOLDER_SUFFIX}
  GATEWAY_PORT=${GATEWAY_PORT:-15888}
  GATEWAY_REPOSITORY_URL=${GATEWAY_REPOSITORY_URL:-"https://github.com/Team-Kujira/gateway.git"}
  GATEWAY_REPOSITORY_BRANCH=${GATEWAY_REPOSITORY_BRANCH:-"community"}
  GATEWAY_CONF_FOLDER="$GATEWAY_FOLDER/conf"
  GATEWAY_LOGS_FOLDER="$GATEWAY_FOLDER/logs"

  # Settings for both
  TAG=${TAG:-"latest"}
  ENTRYPOINT=${ENTRYPOINT:-"/bin/bash"}

	RANDOM_PASSPHRASE=$(generate_passphrase 32)
fi

RESOURCES_FOLDER="$FUN_HB_CLIENT_FOLDER/client/resources"

if [ -n "$RANDOM_PASSPHRASE" ]; then  \
echo "   +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"; \
echo "   |                                                                 |"; \
echo "   |   A new random passphrase will be saved in the file             |"; \
echo "   |                                                                 |"; \
echo "   |     shared/funttastic/client/resources/random_passphrase.txt    |"; \
echo "   |                                                                 |"; \
echo "   |   Copy it to a safe location and delete the file.               |"; \
echo "   |                                                                 |"; \
echo "   +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"; \
echo; \
fi

docker_create_image_fun_hb_client () {
  if [ ! "$FUN_HB_CLIENT_BUILD_CACHE" == "" ]
  then
    BUILT=$(DOCKER_BUILDKIT=1 docker build \
    "$FUN_HB_CLIENT_BUILD_CACHE" \
    --build-arg RANDOM_PASSPHRASE="$RANDOM_PASSPHRASE" \
    --build-arg DEFINED_PASSPHRASE="$DEFINED_PASSPHRASE" \
    -t $FUN_HB_CLIENT_IMAGE_NAME -f ./all/Dockerfile/Dockerfile-Fun-HB-Client .)
  fi
}

docker_create_container_fun_hb_client () {
  $BUILT \
  && docker run \
    -dit \
    --log-opt max-size=10m \
    --log-opt max-file=5 \
    --name $FUN_HB_CLIENT_CONTAINER_NAME \
    --network "$NETWORK" \
    --mount type=bind,source="$RESOURCES_FOLDER",target=/root/app/resources \
    --mount type=bind,source="$CERTS_FOLDER",target=/root/app/resources/certificates \
    --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
    -e RESOURCES_FOLDER="/root/app/resources" \
    -e CERTS_FOLDER="/root/app/resources/certificates" \
    --entrypoint="$ENTRYPOINT" \
    $FUN_HB_CLIENT_IMAGE_NAME:$TAG
}

docker_create_image_hb_client () {
  if [ ! "$HB_CLIENT_BUILD_CACHE" == "" ]
  then
    BUILT=$(DOCKER_BUILDKIT=1 docker build \
    "$HB_CLIENT_BUILD_CACHE" \
    --build-arg REPOSITORY_URL="$HB_CLIENT_REPOSITORY_URL" \
    --build-arg REPOSITORY_BRANCH="$HB_CLIENT_REPOSITORY_BRANCH" \
    -t "$HB_CLIENT_IMAGE_NAME" -f ./all/Dockerfile/Dockerfile-HB-Client .)
  fi
}

docker_create_container_hb_client () {
  $BUILT \
  && docker run \
    -dt \
    --log-opt max-size=10m \
    --log-opt max-file=5 \
    --name "$HB_CLIENT_CONTAINER_NAME" \
    --network "$NETWORK" \
    --mount type=bind,source="$HB_CLIENT_CONF_FOLDER",target=/root/conf \
    --mount type=bind,source="$HB_CLIENT_LOGS_FOLDER",target=/root/logs \
    --mount type=bind,source="$HB_CLIENT_DATA_FOLDER",target=/root/data \
    --mount type=bind,source="$HB_CLIENT_PMM_SCRIPTS_FOLDER",target=/root/pmm_scripts \
    --mount type=bind,source="$HB_CLIENT_SCRIPTS_FOLDER",target=/root/scripts \
    --mount type=bind,source="$CERTS_FOLDER",target=/root/certs \
    --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
    -e HB_CLIENT_CONF_FOLDER="/root/conf" \
    -e HB_CLIENT_LOGS_FOLDER="/root/logs" \
    -e HB_CLIENT_DATA_FOLDER="/root/data" \
    -e HB_CLIENT_PMM_SCRIPTS_FOLDER="/root/pmm_scripts" \
    -e HB_CLIENT_SCRIPTS_FOLDER="/root/scripts" \
    -e CERTS_FOLDER="/root/certs" \
    --entrypoint="$ENTRYPOINT" \
    "$HB_CLIENT_IMAGE_NAME":$TAG
}

docker_create_image_hb_gateway () {
  if [ ! "$GATEWAY_BUILD_CACHE" == "" ]; then
    BUILT=$(DOCKER_BUILDKIT=1 docker build \
      "$GATEWAY_BUILD_CACHE" \
      --build-arg REPOSITORY_URL="$GATEWAY_REPOSITORY_URL" \
      --build-arg REPOSITORY_BRANCH="$GATEWAY_REPOSITORY_BRANCH" \
      --build-arg RANDOM_PASSPHRASE="$RANDOM_PASSPHRASE" \
      --build-arg DEFINED_PASSPHRASE="$DEFINED_PASSPHRASE" \
      -t "$GATEWAY_IMAGE_NAME" -f ./all/Dockerfile/Dockerfile-HB-Gateway .)
  fi
}


docker_create_container_hb_gateway () {
  $BUILT && docker run \
  -dt \
  --log-opt max-size=10m \
  --log-opt max-file=5 \
  -p "$GATEWAY_PORT":"$GATEWAY_PORT" \
  --name "$GATEWAY_CONTAINER_NAME" \
  --network "$NETWORK" \
  --mount type=bind,source="$CERTS_FOLDER",target=/root/certs \
  --mount type=bind,source="$GATEWAY_CONF_FOLDER",target=/root/conf \
  --mount type=bind,source="$GATEWAY_LOGS_FOLDER",target=/root/logs \
  --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
  -e CERTS_FOLDER="/root/certs" \
  -e CONF_FOLDER="/root/conf" \
  -e LOGS_FOLDER="/root/logs" \
  -e GATEWAY_PORT="$GATEWAY_PORT" \
  --entrypoint="$ENTRYPOINT" \
  "$GATEWAY_IMAGE_NAME":$TAG
}

post_installation_fun_hb_client () {
  SELECTED_PASSPHRASE=${RANDOM_PASSPHRASE:-$DEFINED_PASSPHRASE}

  docker exec "$FUN_HB_CLIENT_CONTAINER_NAME" /bin/bash -c "echo '$SELECTED_PASSPHRASE' > selected_passphrase.txt"

  docker exec "$FUN_HB_CLIENT_CONTAINER_NAME" /bin/bash -c "cp -r /root/app/resources_temp/* /root/app/resources"
  docker exec "$FUN_HB_CLIENT_CONTAINER_NAME" /bin/bash -c "rm -rf /root/app/resources_temp"
  docker exec "$FUN_HB_CLIENT_CONTAINER_NAME" /bin/bash -c 'python /root/app/resources/scripts/generate_ssl_certificates.py --passphrase "$(cat selected_passphrase.txt)" --cert-path /root/app/resources/certificates'
  docker exec "$FUN_HB_CLIENT_CONTAINER_NAME" /bin/bash -c 'sed -i "s/<password>/"$(cat selected_passphrase.txt)"/g" /root/app/resources/configuration/production.yml'
  docker exec "$FUN_HB_CLIENT_CONTAINER_NAME" /bin/bash -c "sed -i -e '/telegram:/,/enabled: true/ s/enabled: true/enabled: false/' -e '/telegram:/,/listen_commands: true/ s/listen_commands: true/listen_commands: false/' resources/configuration/common.yml"
  docker exec "$FUN_HB_CLIENT_CONTAINER_NAME" /bin/bash -c "sed -i -e '/logging:/,/use_telegram: true/ s/use_telegram: true/use_telegram: false/' -e '/telegram:/,/enabled: true/ s/enabled: true/enabled: false/' -e '/telegram:/,/listen_commands: true/ s/listen_commands: true/listen_commands: false/' resources/configuration/production.yml"
  docker exec "$FUN_HB_CLIENT_CONTAINER_NAME" /bin/bash -c "groupadd -f $GROUP"
  docker exec "$FUN_HB_CLIENT_CONTAINER_NAME" /bin/bash -c "cd resources && chown -RH :$GROUP ."
  docker exec "$FUN_HB_CLIENT_CONTAINER_NAME" /bin/bash -c "cd resources && chmod -R a+rwX ."
  docker exec "$FUN_HB_CLIENT_CONTAINER_NAME" /bin/bash -c "python app.py" > /dev/null 2>&1 &
  docker exec "$FUN_HB_CLIENT_CONTAINER_NAME" /bin/bash -c 'echo "$(cat selected_passphrase.txt)" > resources/random_passphrase.txt' &> /dev/null

  docker exec "$FUN_HB_CLIENT_CONTAINER_NAME" /bin/bash -c "rm -f selected_passphrase.txt"
}

post_installation_hb_client () {
  docker exec "$HB_CLIENT_CONTAINER_NAME" /bin/bash -c "/root/miniconda3/envs/hummingbot/bin/python3 /root/bin/hummingbot_quickstart.py"
}

post_installation_hb_gateway () {
  docker exec "$GATEWAY_CONTAINER_NAME" /bin/bash -c "cp -R /root/src/templates/. /root/conf"
  docker exec "$GATEWAY_CONTAINER_NAME" /bin/bash -c "groupadd -f $GROUP"
  docker exec "$GATEWAY_CONTAINER_NAME" /bin/bash -c "cd /root/conf && chown -RH :$GROUP ."
  docker exec "$GATEWAY_CONTAINER_NAME" /bin/bash -c "cd /root/conf && chmod -R a+rw ."
  docker exec "$GATEWAY_CONTAINER_NAME" /bin/bash -c "cd /root/logs && chown -RH :$GROUP ."
  docker exec "$GATEWAY_CONTAINER_NAME" /bin/bash -c "cd /root/logs && chmod -R a+rw ."
  docker exec "$GATEWAY_CONTAINER_NAME" /bin/bash -c "yarn start" > /dev/null 2>&1 &
}

choice_one_installation () {
  BUILT=true

  mkdir -p "$SHARED_FOLDER"
  mkdir -p "$CERTS_FOLDER"
  mkdir -p "$RESOURCES_FOLDER"

  # Create a new separated image for Funttastic Hummingbot Client
  docker_create_image_fun_hb_client

  # Create a new separated container from image
  docker_create_container_fun_hb_client

  # Makes some configurations within the container after its creation
  post_installation_fun_hb_client
}

choice_two_installation () {
  BUILT=true

  mkdir -p "$SHARED_FOLDER"
  mkdir -p "$CERTS_FOLDER"
  mkdir -p "$HB_CLIENT_FOLDER"
  mkdir -p "$HB_CLIENT_CONF_FOLDER"
  mkdir -p "$HB_CLIENT_CONF_FOLDER"/connectors
  mkdir -p "$HB_CLIENT_CONF_FOLDER"/strategies
  mkdir -p "$HB_CLIENT_LOGS_FOLDER"
  mkdir -p "$HB_CLIENT_DATA_FOLDER"
  mkdir -p "$HB_CLIENT_PMM_SCRIPTS_FOLDER"
  mkdir -p "$HB_CLIENT_SCRIPTS_FOLDER"

  chmod a+rw "$HB_CLIENT_CONF_FOLDER"

  # Create a new separated image for Hummingbot Client
  docker_create_image_hb_client

  # Create a new separated container from image
  docker_create_container_hb_client

  # Makes some configurations within the container after its creation
#  post_installation_hb_client
}

choice_three_installation () {
  BUILT=true

  mkdir -p "$SHARED_FOLDER"
  mkdir -p "$CERTS_FOLDER"
  mkdir -p "$GATEWAY_FOLDER"
  mkdir -p "$GATEWAY_CONF_FOLDER"
  mkdir -p "$GATEWAY_LOGS_FOLDER"

  chmod a+rw "$GATEWAY_CONF_FOLDER"

  # Create a new separated image for Hummingbot Gateway
  docker_create_image_hb_gateway

  # Create a new separated container from image
  docker_create_container_hb_gateway

  # Makes some configurations within the container after its creation
  post_installation_hb_gateway
}

default_installation () {
  choice_one_installation
  choice_three_installation
}

choice_five_installation () {
  choice_one_installation
  choice_two_installation
  choice_three_installation
}

execute_installation () {
  mkdir -p "$SHARED_FOLDER"
  mkdir -p "$COMMON_FOLDER"

  case $CHOICE in
    1)
        echo
        echo "   Installing:"
        echo
        echo "     > Funttastic Hummingbot Client"
        echo

        choice_one_installation
        ;;
    2)
        echo
        echo "   Installing:"
        echo
        echo "     > Hummingbot Client"
        echo

        choice_two_installation
        ;;
    3)
        echo
        echo "   Installing:"
        echo
        echo "     > Hummingbot Gateway"
        echo

        choice_three_installation
        ;;
    4)
        echo
        echo "   Automatically installing:"
        echo
        echo "     > Funttastic Hummingbot Client"
        echo "     > Hummingbot Gateway"
        echo

        default_installation
        ;;
    5)
        echo
        echo "   Installing:"
        echo
        echo "     > Funttastic Hummingbot Client"
        echo "     > Hummingbot Client"
        echo "     > Hummingbot Gateway"
        echo

        choice_five_installation
  esac
}

install_docker () {
  if [ "$(command -v docker)" ]; then
    execute_installation
  else
    echo "   Docker is not installed."
    echo "   Installing Docker will require superuser permissions."
    read -p "   Do you want to continue? [y/N] >>> " RESPONSE
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
  if [[ "$CHOICE" == 1 || "$CHOICE" == 4 || "$CHOICE" == 5 ]]; then
    echo
    echo "ℹ️  Confirm below if the Funttastic Hummingbot Client instance and its folders are correct:"
    echo
    printf "%25s %5s\n" "Instance name:" "$FUN_HB_CLIENT_CONTAINER_NAME"
    printf "%25s %5s\n" "Version:" "$TAG"
    printf "%25s %5s\n" "Base folder:" "$SHARED_FOLDER_SUFFIX"
    printf "%25s %5s\n" "Funttastic Hummingbot Client folder:" "├── $FUN_HB_CLIENT_FOLDER"
    printf "%25s %5s\n" "Resources folder:" "├── $RESOURCES_FOLDER"
    echo
  fi

  if [[ "$CHOICE" == 2 || "$CHOICE" == 5 ]]; then
    echo
    echo "ℹ️  Confirm below if the instance and its folders are correct:"
    echo
    printf "%25s %5s\n" "Image:"              	"$HB_CLIENT_IMAGE_NAME:$TAG"
    printf "%25s %5s\n" "Instance:"        			"$HB_CLIENT_CONTAINER_NAME"
    printf "%25s %5s\n" "Repository url:"       "$HB_CLIENT_REPOSITORY_URL"
    printf "%25s %5s\n" "Repository branch:"    "$HB_CLIENT_REPOSITORY_BRANCH"
    printf "%25s %5s\n" "Reuse image?:"    		  "$HB_CLIENT_BUILD_CACHE"
    printf "%25s %5s\n" "Entrypoint:"    				"$ENTRYPOINT"
    echo
    printf "%25s %5s\n" "Base:"                 "$SHARED_FOLDER"
    printf "%25s %5s\n" "Common:"               "$COMMON_FOLDER"
    printf "%25s %5s\n" "Certificates:"         "$CERTS_FOLDER"
    printf "%25s %5s\n" "Client:"               "$HB_CLIENT_FOLDER"
    printf "%25s %5s\n" "Config files:"         "$HB_CLIENT_CONF_FOLDER"
    printf "%25s %5s\n" "Log files:"            "$HB_CLIENT_LOGS_FOLDER"
    printf "%25s %5s\n" "Trade and data files:" "$HB_CLIENT_DATA_FOLDER"
    printf "%25s %5s\n" "PMM scripts files:"    "$HB_CLIENT_PMM_SCRIPTS_FOLDER"
    printf "%25s %5s\n" "Scripts files:"        "$HB_CLIENT_SCRIPTS_FOLDER"
    echo
  fi

  if [[ "$CHOICE" == 3 || "$CHOICE" == 4 || "$CHOICE" == 5 ]]; then
    echo
    echo "ℹ️  Confirm below if the instance and its folders are correct:"
    echo
    printf "%25s %5s\n" "Image:"              	"$GATEWAY_IMAGE_NAME:$TAG"
    printf "%25s %5s\n" "Instance:"        			"$GATEWAY_CONTAINER_NAME"
    printf "%25s %5s\n" "Exposed port:"					"$GATEWAY_PORT"
    printf "%25s %5s\n" "Repository url:"       "$GATEWAY_REPOSITORY_URL"
    printf "%25s %5s\n" "Repository branch:"    "$GATEWAY_REPOSITORY_BRANCH"
    printf "%25s %5s\n" "Reuse image?:"    		  "$GATEWAY_BUILD_CACHE"
    printf "%25s %5s\n" "Entrypoint:"    				"$ENTRYPOINT"
    echo
    printf "%25s %5s\n" "Base:"                 "$SHARED_FOLDER"
    printf "%25s %5s\n" "Common:"               "$COMMON_FOLDER"
    printf "%25s %5s\n" "Certificates:"         "$CERTS_FOLDER"
    printf "%25s %5s\n" "Gateway folder:"       "$GATEWAY_FOLDER"
    printf "%25s %5s\n" "Gateway config files:" "$GATEWAY_CONF_FOLDER"
    printf "%25s %5s\n" "Gateway log files:"    "$GATEWAY_LOGS_FOLDER"
    echo
  fi

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
    CHOICE=4
    install_docker
  fi
fi
