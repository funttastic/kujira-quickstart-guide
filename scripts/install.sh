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
OUTPUT_SUPPRESSION_MODE="stdout+stderr"

if [ "$OUTPUT_SUPPRESSION_MODE" == "stdout+stderr" ]; then
#  OUTPUT_SUPPRESSION="&> /dev/null"
  OUTPUT_SUPPRESSION="> /dev/null 2>&1"
elif [ "$OUTPUT_SUPPRESSION_MODE" == "stdout" ]; then
  OUTPUT_SUPPRESSION="> /dev/null"
elif [ "$OUTPUT_SUPPRESSION_MODE" == "stderr" ]; then
  OUTPUT_SUPPRESSION="2> /dev/null"
else
  OUTPUT_SUPPRESSION=""
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
  echo "   ===============    FUNTTASTIC CLIENT INSTALLATION SETUP    ==============="
  echo

  default_values_info

  if [ ! "$CHOICE" == "U1" ]; then
    # Customize the Client image to be used?
    RESPONSE="$FUN_CLIENT_IMAGE_NAME"
    if [ "$RESPONSE" == "" ]
    then
      echo
      read -rp "   Enter a FUNTTASTIC CLIENT image name you want to use (default = \"fun-hb-client\") >>> " RESPONSE
    fi
    if [ "$RESPONSE" == "" ]
    then
      FUN_CLIENT_IMAGE_NAME="fun-hb-client"
    else
      FUN_CLIENT_IMAGE_NAME="$RESPONSE"
    fi
  else
    DEFAULT_IMAGE_NAME="fun-kuji-hb"

    echo
    read -rp "   Enter a name for your new unified image you want to use (default = \"$DEFAULT_IMAGE_NAME\") >>> " RESPONSE

    if [ "$RESPONSE" == "" ]
    then
      UNIFIED_IMAGE_NAME="$DEFAULT_IMAGE_NAME"
    else
      UNIFIED_IMAGE_NAME="$RESPONSE"
    fi
  fi

  if [ ! "$CHOICE" == "U1" ]; then
    APP_NAME="FUNTTASTIC CLIENT"
  else
    APP_NAME="unified"
  fi

  # Create a new image?
  RESPONSE="$FUN_CLIENT_BUILD_CACHE"
  if [ "$RESPONSE" == "" ]
  then
    echo
    read -rp "   Do you want to use an existing "$APP_NAME" image (\"y/N\") >>> " RESPONSE
  fi
  if [[ "$RESPONSE" == "N" || "$RESPONSE" == "n" || "$RESPONSE" == "" ]]
  then
    echo
    echo "      A new image will be created..."

    FUN_CLIENT_BUILD_CACHE="--no-cache"
    UNIFIED_BUILD_CACHE=$FUN_CLIENT_BUILD_CACHE
  else
    FUN_CLIENT_BUILD_CACHE=""
    UNIFIED_BUILD_CACHE=$FUN_CLIENT_BUILD_CACHE
  fi

  if [ ! "$CHOICE" == "U1" ]; then
    # Create a new container?
    RESPONSE="$FUN_CLIENT_CONTAINER_NAME"
    if [ "$RESPONSE" == "" ]
    then
      echo
      read -rp "   Enter a name for your new FUNTTASTIC CLIENT instance (default = \"fun-hb-client\") >>> " RESPONSE
    fi
    if [ "$RESPONSE" == "" ]
    then
      FUN_CLIENT_CONTAINER_NAME="fun-hb-client"
    else
      FUN_CLIENT_CONTAINER_NAME=$RESPONSE
    fi
  else
    DEFAULT_CONTAINER_NAME="fun-kuji-hb"

    echo
    read -rp "   Enter a name for your new unified instance of apps (default = \"$DEFAULT_CONTAINER_NAME\") >>> " RESPONSE

    if [ "$RESPONSE" == "" ]
    then
      UNIFIED_CONTAINER_NAME=$DEFAULT_CONTAINER_NAME
    else
      UNIFIED_CONTAINER_NAME=$RESPONSE
    fi
  fi

  # Prompt the user for the passphrase to encrypt the certificates
  while true; do
      echo
      read -s -rp "   Enter a passphrase to encrypt the certificates with at least $PASSPHRASE_LENGTH characters >>> " DEFINED_PASSPHRASE
      if [ -z "$DEFINED_PASSPHRASE" ] || [ ${#DEFINED_PASSPHRASE} -lt "$PASSPHRASE_LENGTH" ]; then
          echo
          echo
          echo "      Weak passphrase, please try again."
      else
          echo
          break
      fi
  done

  if [ ! "$CHOICE" == "U1" ]
  then
    INSTANCE_TYPE="instance"
  else
    INSTANCE_TYPE="unified instance"
  fi

  # Exposed port?
  RESPONSE="$FUN_CLIENT_PORT"
  if [ "$RESPONSE" == "" ]
  then
    echo
    read -rp "   Enter a port for expose your new FUNTTASTIC CLIENT $INSTANCE_TYPE (default = \"5000\") >>> " RESPONSE
  fi

  if [ "$RESPONSE" == "" ]
  then
    FUN_CLIENT_PORT=5000
  else
    FUN_CLIENT_PORT=$RESPONSE
  fi

  # Location to save files?
  RESPONSE="$FUN_CLIENT_FOLDER"
  if [ "$RESPONSE" == "" ]
  then
    FUN_CLIENT_FOLDER_SUFFIX="funttastic"
    echo
    read -rp "   Enter a folder name where your FUNTTASTIC CLIENT files will be saved
   (default = \"$FUN_CLIENT_FOLDER_SUFFIX\") >>> " RESPONSE
  fi
  if [ "$RESPONSE" == "" ]
  then
    FUN_CLIENT_FOLDER=$SHARED_FOLDER/$FUN_CLIENT_FOLDER_SUFFIX
  elif [[ ${RESPONSE::1} != "/" ]]; then
    FUN_CLIENT_FOLDER=$SHARED_FOLDER/$RESPONSE
  else
    FUN_CLIENT_FOLDER=$RESPONSE
  fi

  RESPONSE="$FUN_CLIENT_REPOSITORY_URL"
  if [ "$RESPONSE" == "" ]
  then
    echo
    read -rp "   Enter the url from the repository to be cloned
   (default = \"https://github.com/funttastic/fun-hb-client.gitt\") >>> " RESPONSE
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
    FUN_CLIENT_AUTO_START="Yes"
  else
    FUN_CLIENT_AUTO_START="No"
  fi

  RESPONSE="$FUN_CLIENT_AUTO_START_EVERY_TIME"
  if [[ "$FUN_CLIENT_AUTO_START" == "Yes" && "$FUN_CLIENT_AUTO_START_EVERY_TIME" == "" ]]
  then
    echo
    read -rp "   Should the Funttastic Client server start automatically every time the container starts?
   If you choose \"No\", you will need to start it manually every time the container starts. (\"Y/n\") >>> " RESPONSE

    if [[ "$RESPONSE" == "Y" || "$RESPONSE" == "y" || "$RESPONSE" == "Yes" || "$RESPONSE" == "yes" || "$RESPONSE" == "" ]]
  then
    echo
    echo "      The Funttastic Client server will start automatically every time the container starts."
    FUN_CLIENT_AUTO_START_EVERY_TIME="Yes"
  else
    FUN_CLIENT_AUTO_START_EVERY_TIME="No"
  fi
  fi
}

pre_installation_hb_client () {
  clear
  echo
  echo
  echo "   ===============   HUMMINGBOT CLIENT INSTALLATION SETUP   ==============="
  echo

  default_values_info

  if [ ! "$CHOICE" == "U1" ]; then
    RESPONSE="$HB_CLIENT_IMAGE_NAME"
    if [ "$RESPONSE" == "" ]
    then
      echo
      read -rp "   Enter a Hummingbot Client image name you want to use (default = \"hb-client\") >>> " RESPONSE
    fi
    if [ "$RESPONSE" == "" ]
    then
      HB_CLIENT_IMAGE_NAME="hb-client"
    else
      HB_CLIENT_IMAGE_NAME="$RESPONSE"
    fi
  fi

  if [ ! "$CHOICE" == "U1" ]; then
    # Create a new image?
    RESPONSE="$HB_CLIENT_BUILD_CACHE"
    if [ "$RESPONSE" == "" ]
    then
      echo
      read -rp "   Do you want to use an existing Hummingbot Client image (\"y/N\") >>> " RESPONSE
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
      read -rp "   Enter a name for your new Hummingbot Client instance (default = \"hb-client\") >>> " RESPONSE
    fi
    if [ "$RESPONSE" == "" ]
    then
      HB_CLIENT_CONTAINER_NAME="hb-client"
    else
      HB_CLIENT_CONTAINER_NAME=$RESPONSE
    fi
  fi

  # Location to save files?
  RESPONSE="$HB_CLIENT_FOLDER"
  if [ "$RESPONSE" == "" ]
  then
    HB_CLIENT_FOLDER_SUFFIX="client"
    echo
    read -rp "   Enter a folder name where your Hummingbot Client files will be saved
   (default = \"$HB_CLIENT_FOLDER_SUFFIX\") >>> " RESPONSE
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
    HB_CLIENT_AUTO_START="Yes"
  else
    HB_CLIENT_AUTO_START="No"
  fi

  HB_CLIENT_CONF_FOLDER="$HB_CLIENT_FOLDER/conf"
  HB_CLIENT_LOGS_FOLDER="$HB_CLIENT_FOLDER/logs"
  HB_CLIENT_DATA_FOLDER="$HB_CLIENT_FOLDER/data"
  HB_CLIENT_PMM_SCRIPTS_FOLDER="$HB_CLIENT_FOLDER/pmm_scripts"
  HB_CLIENT_SCRIPTS_FOLDER="$HB_CLIENT_FOLDER/scripts"
}

pre_installation_hb_gateway () {
  clear
  echo
  echo
  echo "   ===============   HUMMINGBOT GATEWAY INSTALLATION SETUP   ==============="
  echo

  default_values_info

  if [ ! "$CHOICE" == "U1" ]; then
    RESPONSE="$GATEWAY_IMAGE_NAME"
    if [ "$RESPONSE" == "" ]
    then
      echo
      read -rp "   Enter a Hummingbot Gateway image name you want to use (default = \"hb-gateway\") >>> " RESPONSE
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
      read -rp "   Do you want to use an existing Hummingbot Gateway image (\"y/N\") >>> " RESPONSE
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
      read -rp "   Enter a name for your new Hummingbot Gateway instance (default = \"hb-gateway\") >>> " RESPONSE
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
      read -rp "   Enter a port for expose your new Hummingbot Gateway instance (default = \"15888\") >>> " RESPONSE
    fi
    if [ "$RESPONSE" == "" ]
    then
      GATEWAY_PORT=15888
    else
      GATEWAY_PORT=$RESPONSE
    fi
  fi

  # Location to save files?
  RESPONSE="$GATEWAY_FOLDER"
  if [ "$RESPONSE" == "" ]
  then
    GATEWAY_FOLDER_SUFFIX="gateway"
    echo
    read -rp "   Enter a folder name where your Hummingbot Gateway files will be saved
   (default = \"$GATEWAY_FOLDER_SUFFIX\") >>> " RESPONSE
  fi
  if [ "$RESPONSE" == "" ]
  then
    GATEWAY_FOLDER=$SHARED_FOLDER/"hummingbot"/$GATEWAY_FOLDER_SUFFIX
  elif [[ ${RESPONSE::1} != "/" ]]; then
    GATEWAY_FOLDER=$SHARED_FOLDER/"hummingbot"/$RESPONSE
  else
    GATEWAY_FOLDER=$RESPONSE
  fi

  # Executes only if the choice is 3 or U2
  if [ "$CHOICE" == 3 ]; then
    # Prompts user for a password for the gateway certificates
    while true; do
        echo
        read -s -rp "   Enter a passphrase to encrypt the certificates with at least $PASSPHRASE_LENGTH characters >>> " DEFINED_PASSPHRASE
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
    read -rp "   Enter the url from the repository to be cloned
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
    read -rp "   Enter the branch from the repository to be cloned (default = \"community\") >>> " RESPONSE
  fi
  if [ "$RESPONSE" == "" ]
  then
    GATEWAY_REPOSITORY_BRANCH="community"
  else
    GATEWAY_REPOSITORY_BRANCH="$RESPONSE"
  fi

  RESPONSE="$GATEWAY_AUTO_START"
  if [ "$RESPONSE" == "" ]
  then
    echo
    read -rp "   Do you want to start the server automatically after installation? (\"Y/n\") >>> " RESPONSE
  fi

  if [[ "$RESPONSE" == "Y" || "$RESPONSE" == "y" || "$RESPONSE" == "Yes" || "$RESPONSE" == "yes" || "$RESPONSE" == "" ]]
  then
    echo
    echo "      The server will start automatically after installation."
    GATEWAY_AUTO_START="Yes"
  else
    GATEWAY_AUTO_START="No"
  fi

  RESPONSE="$GATEWAY_AUTO_START_EVERY_TIME"
  if [[ "$GATEWAY_AUTO_START" == "Yes" && "$GATEWAY_AUTO_START_EVERY_TIME" == "" ]]
  then
    echo
    read -rp "   Should the Gateway server start automatically every time the container starts?
   If you choose \"No\", you will need to start it manually every time the container starts. (\"Y/n\") >>> " RESPONSE

    if [[ "$RESPONSE" == "Y" || "$RESPONSE" == "y" || "$RESPONSE" == "Yes" || "$RESPONSE" == "yes" || "$RESPONSE" == "" ]]
  then
    echo
    echo "      The Gateway server will start automatically every time the container starts."
    GATEWAY_AUTO_START_EVERY_TIME="Yes"
  else
    GATEWAY_AUTO_START_EVERY_TIME="No"
  fi
  fi

  GATEWAY_CONF_FOLDER="$GATEWAY_FOLDER/conf"
  GATEWAY_LOGS_FOLDER="$GATEWAY_FOLDER/logs"
}

pre_installation_lock_apt () {
  clear
  echo
  echo
  echo "   ======================  LOCK ADDING NEW PROGRAMS   ======================"
  echo

  default_values_info

  RESPONSE="$LOCK_APT"
  if [ "$RESPONSE" == "" ]
  then
    echo
    read -rp "   Do you want to eliminate the possibility of installing new programs in the
   container system after its creation? (\"y/N\") >>> " RESPONSE
  fi
  if [[ "$RESPONSE" == "N" || "$RESPONSE" == "n" || "$RESPONSE" == "No" || "$RESPONSE" == "no" || "$RESPONSE" == "" ]]
  then
    echo
    echo "      The installation of new programs will be allowed."
    LOCK_APT="No"
    sleep 3
  else
    echo
    echo "      You have chosen to block the addition of new programs."
    LOCK_APT="Yes"
    sleep 3
  fi
}

clear
echo
echo "   ============================     INSTALLATION OPTIONS     ==========================="
echo

echo "   Do you want to install apps in individual containers? [Y/n]"
echo
echo "ℹ️  Enter the value [0] to return to the main menu."
echo

read -rp "   [Y/n/0] >>> " RESPONSE
if [[ "$RESPONSE" == "Y" || "$RESPONSE" == "y" || "$RESPONSE" == "" ]]
then
  INDIVIDUAL_CONTAINERS="True"
  echo
  echo "   [i] A separate container will be created for each app."
elif [[ "$RESPONSE" == "0" ]]; then
  clear
  ./configure
  exit 0
else
  INDIVIDUAL_CONTAINERS="False"
  echo
  echo "   [i] A single container will be created for all apps."
fi

echo
echo
echo "   Do you want to automate the entire process,
   including setting a random passphrase? [Y/n]"

echo
echo "ℹ️  Enter the value [0] to return to the previous question."
echo

read -rp "   [Y/n/0] >>> " RESPONSE
if [[ "$RESPONSE" == "Y" || "$RESPONSE" == "y" || "$RESPONSE" == "" ]]
then
  echo
elif [[ "$RESPONSE" == "0" ]]; then
  clear
  ./all/install.sh
  exit 0
else
  CUSTOMIZE="--customize"
fi

if [ "$CUSTOMIZE" == "--customize" ]
then
  if [ "$INDIVIDUAL_CONTAINERS" == "True" ]; then
    clear
    echo
    echo "   CHOOSE WHICH INSTALLATION YOU WOULD LIKE TO DO:"
    echo
    echo "   [1] FUNTTASTIC CLIENT"
    echo "   [2] HUMMINGBOT CLIENT"
    echo "   [3] HUMMINGBOT GATEWAY"
    echo "   [4] FUNTTASTIC CLIENT and HUMMINGBOT GATEWAY [RECOMMENDED]"
    echo "   [5] ALL"
    echo
    echo "   [0] RETURN TO MAIN MENU"
    echo
    echo "   For more information about the FUNTTASTIC CLIENT, please visit:"
    echo
    echo "         https://www.funttastic.com/partners/kujira"
    echo

    read -rp "   Enter your choice (1-5): " CHOICE

    while true; do
      case $CHOICE in
          1|2|3|4|5|0)
              break
              ;;
          *)
              echo
              echo "   [!] Invalid Input. Enter a number between 1 and 5."
              echo
              ;;
      esac

      read -rp "   Enter your choice (1-5): " CHOICE
    done

    case $CHOICE in
        1)
            pre_installation_fun_client
            pre_installation_lock_apt
            ;;
        2)
            pre_installation_hb_client
            pre_installation_lock_apt
            ;;
        3)
            pre_installation_hb_gateway
            pre_installation_lock_apt
            ;;
        4)
            pre_installation_fun_client
            pre_installation_hb_gateway
            pre_installation_lock_apt
            ;;
        5)
            pre_installation_fun_client
            pre_installation_hb_gateway
            pre_installation_hb_client
            pre_installation_lock_apt
            ;;
        0)
            clear
            ./configure
            ;;
    esac
  else
    CHOICE="U1"
    pre_installation_fun_client
    pre_installation_hb_gateway
    pre_installation_hb_client
    pre_installation_lock_apt
  fi
else
  # Default settings to install FUNTTASTIC CLIENT, Hummingbot Gateway and Hummingbot Client

  # FUNTTASTIC CLIENT Settings
  FUN_CLIENT_IMAGE_NAME=${FUN_CLIENT_IMAGE_NAME:-"fun-hb-client"}
  FUN_CLIENT_CONTAINER_NAME=${FUN_CLIENT_CONTAINER_NAME:-"fun-hb-client"}
  FUN_CLIENT_FOLDER_SUFFIX=${FUN_CLIENT_FOLDER_SUFFIX:-"funttastic"}
  FUN_CLIENT_FOLDER="$SHARED_FOLDER"/"$FUN_CLIENT_FOLDER_SUFFIX"
  FUN_CLIENT_PORT=${FUN_CLIENT_PORT:-5000}
  FUN_CLIENT_BUILD_CACHE=${FUN_CLIENT_BUILD_CACHE:-"--no-cache"}
  FUN_CLIENT_REPOSITORY_URL=${FUN_CLIENT_REPOSITORY_URL:-"https://github.com/funttastic/fun-hb-client.git"}
  FUN_CLIENT_REPOSITORY_BRANCH=${FUN_CLIENT_REPOSITORY_BRANCH:-"community"}
  FUN_CLIENT_AUTO_START=${FUN_CLIENT_AUTO_START:-"Yes"}
  SSH_PUBLIC_KEY="$SSH_PUBLIC_KEY"
  SSH_PRIVATE_KEY="$SSH_PRIVATE_KEY"

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
  HB_CLIENT_AUTO_START=${HB_CLIENT_AUTO_START:-"Yes"}

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
  GATEWAY_AUTO_START=${GATEWAY_AUTO_START:-"Yes"}

  UNIFIED_IMAGE_NAME="fun-kuji-hb"
  UNIFIED_CONTAINER_NAME="$UNIFIED_IMAGE_NAME"

  # Settings for both
  TAG=${TAG:-"latest"}
  ENTRYPOINT=${ENTRYPOINT:-"/bin/bash"}
  LOCK_APT=${LOCK_APT:-"No"}

	RANDOM_PASSPHRASE=$(generate_passphrase 32)
fi

FUN_CLIENT_RESOURCES_FOLDER="$FUN_CLIENT_FOLDER/client/resources"
SELECTED_PASSPHRASE=${RANDOM_PASSPHRASE:-$DEFINED_PASSPHRASE}
if [[ "$SSH_PUBLIC_KEY" && "$SSH_PRIVATE_KEY" ]]; then
    FUN_CLIENT_REPOSITORY_URL="git@github.com:funttastic/fun-hb-client.git"
fi

if [ "$CHOICE" == "U1" ]; then
  FUN_CLIENT_APP_PATH_PREFIX="/root/funttastic/client"
  GATEWAY_APP_PATH_PREFIX="/root/hummingbot/gateway"
  HB_CLIENT_APP_PATH_PREFIX="/root/hummingbot/client"

  FUN_CLIENT_CONTAINER_NAME="$UNIFIED_CONTAINER_NAME"
  GATEWAY_CONTAINER_NAME="$UNIFIED_CONTAINER_NAME"
  HB_CLIENT_CONTAINER_NAME="$UNIFIED_CONTAINER_NAME"
else
  FUN_CLIENT_APP_PATH_PREFIX="/root"
  GATEWAY_APP_PATH_PREFIX="/root"
  HB_CLIENT_APP_PATH_PREFIX="/root"
fi

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

docker_create_image_fun_client () {
  if [ ! "$FUN_CLIENT_BUILD_CACHE" == "" ]
  then
    BUILT=$(DOCKER_BUILDKIT=1 docker build \
    "$FUN_CLIENT_BUILD_CACHE" \
    --build-arg SSH_PUBLIC_KEY="$SSH_PUBLIC_KEY" \
    --build-arg SSH_PRIVATE_KEY="$SSH_PRIVATE_KEY" \
    --build-arg REPOSITORY_URL="$FUN_CLIENT_REPOSITORY_URL" \
    --build-arg REPOSITORY_BRANCH="$FUN_CLIENT_REPOSITORY_BRANCH" \
    -t "$FUN_CLIENT_IMAGE_NAME" -f ./all/Dockerfile/fun-hb-client/Dockerfile .)
  fi
}

docker_create_container_fun_client () {
  $BUILT \
  && docker run \
    -dit \
    --log-opt max-size=10m \
    --log-opt max-file=5 \
    --name "$FUN_CLIENT_CONTAINER_NAME" \
    --network "$NETWORK" \
    --mount type=bind,source="$FUN_CLIENT_RESOURCES_FOLDER",target=/root/resources \
    --mount type=bind,source="$CERTS_FOLDER",target=/root/resources/certificates \
    --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
    -e FUN_CLIENT_RESOURCES_FOLDER="/root/resources" \
    -e CERTS_FOLDER="/root/resources/certificates" \
    -e PORT="$FUN_CLIENT_PORT" \
    --entrypoint="$ENTRYPOINT" \
    "$FUN_CLIENT_IMAGE_NAME":$TAG
}

docker_create_image_hb_client () {
  if [ ! "$HB_CLIENT_BUILD_CACHE" == "" ]
  then
    BUILT=$(DOCKER_BUILDKIT=1 docker build \
    "$HB_CLIENT_BUILD_CACHE" \
    --build-arg REPOSITORY_URL="$HB_CLIENT_REPOSITORY_URL" \
    --build-arg REPOSITORY_BRANCH="$HB_CLIENT_REPOSITORY_BRANCH" \
    -t "$HB_CLIENT_IMAGE_NAME" -f ./all/Dockerfile/hb-client/Dockerfile .)
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
    -e COMMAND="$COMMAND" \
    --entrypoint="$ENTRYPOINT" \
    "$HB_CLIENT_IMAGE_NAME":$TAG
}

docker_create_image_hb_gateway () {
  if [ ! "$GATEWAY_BUILD_CACHE" == "" ]; then
    BUILT=$(DOCKER_BUILDKIT=1 docker build \
      "$GATEWAY_BUILD_CACHE" \
      --build-arg REPOSITORY_URL="$GATEWAY_REPOSITORY_URL" \
      --build-arg REPOSITORY_BRANCH="$GATEWAY_REPOSITORY_BRANCH" \
      -t "$GATEWAY_IMAGE_NAME" -f ./all/Dockerfile/hb-gateway/Dockerfile .)
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

unified_docker_create_image () {
  if [ "$FUN_CLIENT_AUTO_START_EVERY_TIME" == "Yes" ]; then
    FUN_CLIENT_COMMAND="conda activate funttastic && python "$FUN_CLIENT_APP_PATH_PREFIX"/app.py "$OUTPUT_SUPPRESSION" &"
  else
    FUN_CLIENT_COMMAND="#"
  fi

  if [ "$GATEWAY_AUTO_START_EVERY_TIME" == "Yes" ]; then
    GATEWAY_COMMAND="cd "$GATEWAY_APP_PATH_PREFIX" && yarn start "$OUTPUT_SUPPRESSION" &"
  else
    GATEWAY_COMMAND="#"
  fi

  # if [ "$HB_CLIENT_AUTO_START_EVERY_TIME" == "Yes" ]; then
  #   HB_CLIENT_COMMAND="conda activate hummingbot && cd /root/hummingbot/client && ./bin/hummingbot_quickstart.py 2>> ./logs/errors.log"
  # else
  #   HB_CLIENT_COMMAND="#"
  # fi

  if [ ! "$UNIFIED_BUILD_CACHE" == "" ]
  then
    BUILT=$(DOCKER_BUILDKIT=1 docker build \
    --build-arg SSH_PUBLIC_KEY="$SSH_PUBLIC_KEY" \
    --build-arg SSH_PRIVATE_KEY="$SSH_PRIVATE_KEY" \
    --build-arg GATEWAY_PASSPHRASE="$SELECTED_PASSPHRASE" \
    --build-arg RANDOM_PASSPHRASE="$RANDOM_PASSPHRASE" \
    --build-arg FUN_CLIENT_REPOSITORY_URL="$FUN_CLIENT_REPOSITORY_URL" \
    --build-arg FUN_CLIENT_REPOSITORY_BRANCH="$FUN_CLIENT_REPOSITORY_BRANCH" \
    --build-arg HB_CLIENT_REPOSITORY_URL="$HB_CLIENT_REPOSITORY_URL" \
    --build-arg HB_CLIENT_REPOSITORY_BRANCH="$HB_CLIENT_REPOSITORY_BRANCH" \
    --build-arg GATEWAY_REPOSITORY_URL="$GATEWAY_REPOSITORY_URL" \
    --build-arg GATEWAY_REPOSITORY_BRANCH="$GATEWAY_REPOSITORY_BRANCH" \
    --build-arg HOST_USER_GROUP="$GROUP" \
    --build-arg LOCK_APT="$LOCK_APT" \
    --build-arg FUN_CLIENT_COMMAND="$FUN_CLIENT_COMMAND" \
    --build-arg GATEWAY_COMMAND="$GATEWAY_COMMAND" \
    --build-arg HB_CLIENT_COMMAND="$HB_CLIENT_COMMAND" \
    -t "$UNIFIED_IMAGE_NAME" -f ./all/Dockerfile/unified/Dockerfile .)
  fi
}

unified_docker_create_container () {
  $BUILT \
  && docker run \
    -dit \
    --log-opt max-size=10m \
    --log-opt max-file=5 \
    --name "$UNIFIED_CONTAINER_NAME" \
    --network "$NETWORK" \
    --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
    -e FUN_CLIENT_RESOURCES_FOLDER="/root/funttastic/client/resources" \
    -e HB_CLIENT_CONF_FOLDER="/root/hummingbot/client/conf" \
    -e HB_CLIENT_LOGS_FOLDER="/root/hummingbot/client/logs" \
    -e HB_CLIENT_DATA_FOLDER="/root/hummingbot/client/data" \
    -e HB_CLIENT_SCRIPTS_FOLDER="/root/hummingbot/client/scripts" \
    -e HB_CLIENT_PMM_SCRIPTS_FOLDER="/root/hummingbot/client/pmm_scripts" \
    -e GATEWAY_CONF_FOLDER="/root/hummingbot/gateway/conf" \
    -e GATEWAY_LOGS_FOLDER="/root/hummingbot/gateway/logs" \
    -e FUN_CLIENT_PORT="$FUN_CLIENT_PORT" \
    -e GATEWAY_PORT="$GATEWAY_PORT" \
    -e FUN_CLIENT_COMMAND="$FUN_CLIENT_COMMAND" \
    -e GATEWAY_COMMAND="$GATEWAY_COMMAND" \
    -e HB_CLIENT_COMMAND="$HB_CLIENT_COMMAND" \
    --entrypoint="$ENTRYPOINT" \
    "$UNIFIED_IMAGE_NAME":$TAG
}

post_installation_fun_client () {
  if [[ "$FUN_CLIENT_AUTO_START" == "Yes" && "$FUN_CLIENT_AUTO_START_EVERY_TIME" == "No" ]]; then
    docker exec -it "$FUN_CLIENT_CONTAINER_NAME" /bin/bash -lc "conda activate funttastic && python "$FUN_CLIENT_APP_PATH_PREFIX"/app.py "$OUTPUT_SUPPRESSION" &"
  fi
}

post_installation_hb_gateway () {
  if [[ "$GATEWAY_AUTO_START" == "Yes" && "$GATEWAY_AUTO_START_EVERY_TIME" == "No" ]]; then
    docker exec -it "$GATEWAY_CONTAINER_NAME" /bin/bash -lc "cd "$GATEWAY_APP_PATH_PREFIX" && yarn start "$OUTPUT_SUPPRESSION" &"
  fi
}

post_installation_hb_client () {
  if [ "$HB_CLIENT_AUTO_START" == "Yes" ]; then
    docker exec -it "$HB_CLIENT_CONTAINER_NAME" /bin/bash -lc "conda activate hummingbot && cd /root/hummingbot/client && ./bin/hummingbot_quickstart.py 2>> ./logs/errors.log"
  fi
}

choice_one_installation () {
  BUILT=true

  mkdir -p "$SHARED_FOLDER"
  mkdir -p "$CERTS_FOLDER"
  mkdir -p "$FUN_CLIENT_RESOURCES_FOLDER"

  # Create a new separated image for FUNTTASTIC CLIENT
  docker_create_image_fun_client

  # Create a new separated container from image
  docker_create_container_fun_client

  # Makes some configurations within the container after its creation
  post_installation_fun_client
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
  post_installation_hb_client
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

unified_installation () {
  mkdir -p "$SHARED_FOLDER"
  mkdir -p "$CERTS_FOLDER"

  mkdir -p "$FUN_CLIENT_RESOURCES_FOLDER"

  mkdir -p "$HB_CLIENT_FOLDER"
  mkdir -p "$HB_CLIENT_CONF_FOLDER"
  mkdir -p "$HB_CLIENT_CONF_FOLDER"/connectors
  mkdir -p "$HB_CLIENT_CONF_FOLDER"/strategies
  mkdir -p "$HB_CLIENT_LOGS_FOLDER"
  mkdir -p "$HB_CLIENT_DATA_FOLDER"
  mkdir -p "$HB_CLIENT_PMM_SCRIPTS_FOLDER"
  mkdir -p "$HB_CLIENT_SCRIPTS_FOLDER"

  chmod a+rw "$HB_CLIENT_CONF_FOLDER"

  mkdir -p "$GATEWAY_FOLDER"
  mkdir -p "$GATEWAY_CONF_FOLDER"
  mkdir -p "$GATEWAY_LOGS_FOLDER"

  chmod a+rw "$GATEWAY_CONF_FOLDER"

  unified_docker_create_image
  unified_docker_create_container

  post_installation_fun_client
  post_installation_hb_gateway
  post_installation_hb_client
}

execute_installation () {
  mkdir -p "$SHARED_FOLDER"
  mkdir -p "$COMMON_FOLDER"

  if [ "$INDIVIDUAL_CONTAINERS" == "False" ]; then
    case $CHOICE in
      1)
          CHOICE="U1"
          ;;
      2)
          CHOICE="U2"
          ;;
      3)
          CHOICE="U3"
          ;;
    esac
  fi

  case $CHOICE in
    1)
        echo
        echo "   Installing:"
        echo
        echo "     > FUNTTASTIC CLIENT"
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
        echo "   Installing:"
        echo
        echo "     > FUNTTASTIC CLIENT"
        echo "     > Hummingbot Gateway"
        echo

        default_installation
        ;;
    5)
        echo
        echo "   Installing:"
        echo
        echo "     > FUNTTASTIC CLIENT"
        echo "     > Hummingbot Client"
        echo "     > Hummingbot Gateway"
        echo

        choice_five_installation
        ;;
    "U1")
        echo
        echo "   Installing:"
        echo
        echo "     > FUNTTASTIC CLIENT"
        echo "     > Hummingbot Client"
        echo "     > Hummingbot Gateway"
        echo
        echo "     [i] All in just one container."
        echo

        unified_installation
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
  if [ "$CHOICE" == "U1" ]; then
    printf "%25s %5s\n" "Image:"              	"$UNIFIED_IMAGE_NAME"
    printf "%25s %5s\n" "Instance:"        			"$UNIFIED_CONTAINER_NAME"
    printf "%25s %5s\n" "Reuse image?:"    		  "$UNIFIED_BUILD_CACHE"
  fi
  printf "%25s %5s\n" "Version:"              "$TAG"
  printf "%25s %5s\n" "Base:"                 "$SHARED_FOLDER"
  if [ ! "$CHOICE" == "U1" ]; then
    printf "%25s %5s\n" "Common:"               "$COMMON_FOLDER"
    printf "%25s %5s\n" "Certificates:"         "$CERTS_FOLDER"
  fi
  printf "%25s %5s\n" "Entrypoint:"    				"$ENTRYPOINT"
  echo

  if [[ "$CHOICE" == 1 || "$CHOICE" == 4 || "$CHOICE" == 5 || "$CHOICE" == "U1" ]]; then

    if [ "$CHOICE" == "U1" ]; then
      FUN_CLIENT_IMAGE_NAME="$UNIFIED_IMAGE_NAME"
      FUN_CLIENT_CONTAINER_NAME="$UNIFIED_CONTAINER_NAME"
    fi

    echo
    echo "ℹ️  Confirm below if the FUNTTASTIC CLIENT instance and its folders are correct:"
    echo
    if [ ! "$CHOICE" == "U1" ]; then
      printf "%25s %5s\n" "Image:"              	"$FUN_CLIENT_IMAGE_NAME:$TAG"
      printf "%25s %5s\n" "Instance:"        			"$FUN_CLIENT_CONTAINER_NAME"
    fi
    printf "%25s %5s\n" "Repository url:"       "$FUN_CLIENT_REPOSITORY_URL"
    printf "%25s %5s\n" "Repository branch:"    "$FUN_CLIENT_REPOSITORY_BRANCH"
    printf "%25s %4s\n" "Exposed port:"					"$FUN_CLIENT_PORT"
    if [ ! "$CHOICE" == "U1" ]; then
      printf "%25s %5s\n" "Reuse image?:"    		  "$FUN_CLIENT_BUILD_CACHE"
    fi
    printf "%25s %3s\n" "Autostart:"    		    "$FUN_CLIENT_AUTO_START"
    echo
    printf "%25s %5s\n" "FUN Client folder:" "$FUN_CLIENT_FOLDER"
    printf "%25s %5s\n" "Resources folder:"     "$FUN_CLIENT_RESOURCES_FOLDER"
    echo
  fi

  if [[ "$CHOICE" == 2 || "$CHOICE" == 5 || "$CHOICE" == "U1" ]]; then

    if [ "$CHOICE" == "U1" ]; then
      HB_CLIENT_IMAGE_NAME="$UNIFIED_IMAGE_NAME"
      HB_CLIENT_CONTAINER_NAME="$UNIFIED_CONTAINER"
    fi

    echo
    echo "ℹ️  Confirm below if the Hummingbot Client instance and its folders are correct:"
    echo
    if [ ! "$CHOICE" == "U1" ]; then
      printf "%25s %5s\n" "Image:"              	"$HB_CLIENT_IMAGE_NAME:$TAG"
      printf "%25s %5s\n" "Instance:"        			"$HB_CLIENT_CONTAINER_NAME"
    fi
    printf "%25s %5s\n" "Repository url:"       "$HB_CLIENT_REPOSITORY_URL"
    printf "%25s %5s\n" "Repository branch:"    "$HB_CLIENT_REPOSITORY_BRANCH"
    if [ ! "$CHOICE" == "U1" ]; then
      printf "%25s %5s\n" "Reuse image?:"    		  "$HB_CLIENT_BUILD_CACHE"
    fi
    printf "%25s %3s\n" "Autostart:"    		    "$HB_CLIENT_AUTO_START"
    echo
    printf "%25s %5s\n" "Client folder:"        "$HB_CLIENT_FOLDER"
    printf "%25s %5s\n" "Config files:"         "$HB_CLIENT_CONF_FOLDER"
    printf "%25s %5s\n" "Log files:"            "$HB_CLIENT_LOGS_FOLDER"
    printf "%25s %5s\n" "Trade and data files:" "$HB_CLIENT_DATA_FOLDER"
    printf "%25s %5s\n" "PMM scripts files:"    "$HB_CLIENT_PMM_SCRIPTS_FOLDER"
    printf "%25s %5s\n" "Scripts files:"        "$HB_CLIENT_SCRIPTS_FOLDER"
    echo
  fi

  if [[ ! "$CHOICE" == 1 && ! "$CHOICE" == 2 ]]; then
    if [ "$CHOICE" == "U1" ]; then
      if [ -n "$UNIFIED_IMAGE_NAME" ]
      then
        GATEWAY_IMAGE_NAME="$UNIFIED_IMAGE_NAME"
        GATEWAY_CONTAINER_NAME="$UNIFIED_CONTAINER_NAME"
      fi
    fi

    echo
    echo "ℹ️  Confirm below if the Hummingbot Gateway instance and its folders are correct:"
    echo
    if [ ! "$CHOICE" == "U1" ]; then
      printf "%25s %5s\n" "Image:"              	"$GATEWAY_IMAGE_NAME:$TAG"
      printf "%25s %5s\n" "Instance:"        			"$GATEWAY_CONTAINER_NAME"
      printf "%25s %4s\n" "Exposed port:"					"$GATEWAY_PORT"
    fi
    printf "%25s %5s\n" "Repository url:"       "$GATEWAY_REPOSITORY_URL"
    printf "%25s %5s\n" "Repository branch:"    "$GATEWAY_REPOSITORY_BRANCH"
    if [ ! "$CHOICE" == "U1" ]; then
      printf "%25s %5s\n" "Reuse image?:"    		  "$GATEWAY_BUILD_CACHE"
    fi
    printf "%25s %3s\n" "Autostart:"    		    "$GATEWAY_AUTO_START"
    echo
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
    if [ "$INDIVIDUAL_CONTAINERS" == "True" ]; then
      CHOICE=4
    else
      CHOICE="U1"
    fi
    install_docker
  fi
fi
