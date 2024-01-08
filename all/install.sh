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

pre_installation_fun_hb_client () {
  clear
  echo
  echo
  echo "   ===============    FUNTTASTIC HUMMINGBOT CLIENT INSTALLATION SETUP    ==============="
  echo

  default_values_info

  if [[ ! "$CHOICE" == "U1" && ! "$CHOICE" == "U3" ]]; then
    # Customize the Client image to be used?
    RESPONSE="$FUN_HB_CLIENT_IMAGE_NAME"
    if [ "$RESPONSE" == "" ]
    then
      echo
      read -rp "   Enter a Funttastic Hummingbot Client image name you want to use (default = \"fun-hb-client\") >>> " RESPONSE
    fi
    if [ "$RESPONSE" == "" ]
    then
      FUN_HB_CLIENT_IMAGE_NAME="fun-hb-client"
    else
      FUN_HB_CLIENT_IMAGE_NAME="$RESPONSE"
    fi
  else
    # Customize the unified choice 1 and 3 image name to be used?
    if [ "$CHOICE" == "U1" ]; then
      DEFAULT_NAME="fun-hb-client-and-hb-gateway"
    else
      DEFAULT_NAME="all-apps"
    fi

    echo
    read -rp "   Enter a name for your new unified image fot Funttastic Hummingbot Client and Hummingbot Gateway
   (default = \"$DEFAULT_NAME\") >>> " RESPONSE

    if [ "$RESPONSE" == "" ]
    then
      if [ "$CHOICE" == "U1" ]; then
        UNIFIED_IMAGE_NAME_CHOICE_1="$DEFAULT_NAME"
      else
        UNIFIED_IMAGE_NAME_CHOICE_3="$DEFAULT_NAME"
      fi
    else
      if [ "$CHOICE" == "U1" ]; then
        UNIFIED_IMAGE_NAME_CHOICE_1="$RESPONSE"
      else
        UNIFIED_IMAGE_NAME_CHOICE_3="$RESPONSE"
      fi
    fi
  fi

  # Create a new image?
  RESPONSE="$FUN_HB_CLIENT_BUILD_CACHE"
  if [ "$RESPONSE" == "" ]
  then
    echo
    read -rp "   Do you want to use an existing Funttastic Hummingbot Client image (\"y/N\") >>> " RESPONSE
  fi
  if [[ "$RESPONSE" == "N" || "$RESPONSE" == "n" || "$RESPONSE" == "" ]]
  then
    echo
    echo "      A new image will be created..."
    FUN_HB_CLIENT_BUILD_CACHE="--no-cache"
  else
    FUN_HB_CLIENT_BUILD_CACHE=""
  fi

  if [[ ! "$CHOICE" == "U1" && ! "$CHOICE" == "U3" ]]; then
    # Create a new container?
    RESPONSE="$FUN_HB_CLIENT_CONTAINER_NAME"
    if [ "$RESPONSE" == "" ]
    then
      echo
      read -rp "   Enter a name for your new Funttastic Hummingbot Client instance (default = \"fun-hb-client\") >>> " RESPONSE
    fi
    if [ "$RESPONSE" == "" ]
    then
      FUN_HB_CLIENT_CONTAINER_NAME="fun-hb-client"
    else
      FUN_HB_CLIENT_CONTAINER_NAME=$RESPONSE
    fi
  else
    # Customize the unified choice 1 and 3 container name to be used?
    if [ "$CHOICE" == "U1" ]; then
      DEFAULT_NAME="fun-hb-client-and-hb-gateway"
    else
      DEFAULT_NAME="all-apps"
    fi

    echo
    read -rp "   Enter a name for your new unified instance of Funttastic Hummingbot Client and Hummingbot Gateway
   (default = \"$DEFAULT_NAME\") >>> " RESPONSE

    if [ "$RESPONSE" == "" ]
    then
      if [ "$CHOICE" == "U1" ]; then
        UNIFIED_CONTAINER_NAME_CHOICE_1="$DEFAULT_NAME"
      else
        UNIFIED_CONTAINER_NAME_CHOICE_3="$DEFAULT_NAME"
      fi
    else
      if [ "$CHOICE" == "U1" ]; then
        UNIFIED_CONTAINER_NAME_CHOICE_1="$RESPONSE"
      else
        UNIFIED_CONTAINER_NAME_CHOICE_3="$RESPONSE"
      fi
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

  # Exposed port?
  RESPONSE="$FUN_HB_CLIENT_PORT"
  if [ "$RESPONSE" == "" ]
  then
    echo
    read -rp "   Enter a port for expose your new Funttastic Hummingbot Client instance (default = \"5000\") >>> " RESPONSE
  fi
  if [ "$RESPONSE" == "" ]
  then
    FUN_HB_CLIENT_PORT=5000
  else
    FUN_HB_CLIENT_PORT=$RESPONSE
  fi

  # Location to save files?
  RESPONSE="$FUN_HB_CLIENT_FOLDER"
  if [ "$RESPONSE" == "" ]
  then
    FUN_HB_CLIENT_FOLDER_SUFFIX="funttastic"
    echo
    read -rp "   Enter a folder name where your Funttastic Hummingbot Client files will be saved
   (default = \"$FUN_HB_CLIENT_FOLDER_SUFFIX\") >>> " RESPONSE
  fi
  if [ "$RESPONSE" == "" ]
  then
    FUN_HB_CLIENT_FOLDER=$SHARED_FOLDER/$FUN_HB_CLIENT_FOLDER_SUFFIX
  elif [[ ${RESPONSE::1} != "/" ]]; then
    FUN_HB_CLIENT_FOLDER=$SHARED_FOLDER/$RESPONSE
  else
    FUN_HB_CLIENT_FOLDER=$RESPONSE
  fi

  RESPONSE="$FUN_HB_CLIENT_REPOSITORY_URL"
  if [ "$RESPONSE" == "" ]
  then
    echo
    read -rp "   Enter the url from the repository to be cloned
   (default = \"https://github.com/funttastic/fun-hb-client.gitt\") >>> " RESPONSE
  fi
  if [ "$RESPONSE" == "" ]
  then
    FUN_HB_CLIENT_REPOSITORY_URL="https://github.com/funttastic/fun-hb-client.git"
  else
    FUN_HB_CLIENT_REPOSITORY_URL="$RESPONSE"
  fi

  RESPONSE="$FUN_HB_CLIENT_REPOSITORY_BRANCH"
  if [ "$RESPONSE" == "" ]
  then
    echo
    read -rp "   Enter the branch from the repository to be cloned (default = \"community\") >>> " RESPONSE
  fi
  if [ "$RESPONSE" == "" ]
  then
    FUN_HB_CLIENT_REPOSITORY_BRANCH="community"
  else
    FUN_HB_CLIENT_REPOSITORY_BRANCH="$RESPONSE"
  fi

  RESPONSE="$FUN_HB_CLIENT_AUTO_START"
  if [ "$RESPONSE" == "" ]
  then
    echo
    read -rp "   Do you want to start the server automatically after installation? (\"Y/n\") >>> " RESPONSE
  fi
  if [[ "$RESPONSE" == "Y" || "$RESPONSE" == "y" || "$RESPONSE" == "Yes" || "$RESPONSE" == "yes" || "$RESPONSE" == "" ]]
  then
    echo
    echo "      The server will start automatically after installation."
    FUN_HB_CLIENT_AUTO_START=1
  else
    FUN_HB_CLIENT_AUTO_START=0
  fi
}

pre_installation_hb_client () {
  clear
  echo
  echo
  echo "   ===============   HUMMINGBOT CLIENT INSTALLATION SETUP   ==============="
  echo

  default_values_info

  if [[ ! "$CHOICE" == "U1" && ! "$CHOICE" == "U2" && ! "$CHOICE" == "U3" ]]; then
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
  else
    # Customize the unified choice 2 image name to be used?
    # For choice 3 it is already being defined from the pre-installation of "Funttastic Hummingbot Client"

    DEFAULT_NAME="hb-client-and-hb-gateway"

    if [ "$CHOICE" == "U2" ]; then
      echo
      read -rp "   Enter a name for your new unified image for Hummingbot Client and Hummingbot Gateway
   (default = \"$DEFAULT_NAME\") >>> " RESPONSE

      if [ "$RESPONSE" == "" ]
      then
        UNIFIED_IMAGE_NAME_CHOICE_2="$DEFAULT_NAME"
      else
        UNIFIED_IMAGE_NAME_CHOICE_2="$RESPONSE"
      fi
    fi
  fi

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

  if [[ ! "$CHOICE" == "U1" && ! "$CHOICE" == "U2" && ! "$CHOICE" == "U3" ]]; then
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
  else
    # Customize the unified choice 2 and 3 container name to be used?
    if [ "$CHOICE" == "U2" ]; then
      DEFAULT_NAME="hb-client-and-hb-gateway"
    else
      DEFAULT_NAME="all-apps"
    fi

    echo
    read -rp "   Enter a name for your new unified instance for Hummingbot Client and Hummingbot Gateway
   (default = \"$DEFAULT_NAME\") >>> " RESPONSE

    if [ "$RESPONSE" == "" ]
    then
      if [ "$CHOICE" == "U2" ]; then
        UNIFIED_CONTAINER_NAME_CHOICE_2="$DEFAULT_NAME"
      else
        UNIFIED_CONTAINER_NAME_CHOICE_3="$DEFAULT_NAME"
      fi
    else
      if [ "$CHOICE" == "U2" ]; then
        UNIFIED_CONTAINER_NAME_CHOICE_2="$RESPONSE"
      else
        UNIFIED_CONTAINER_NAME_CHOICE_3="$RESPONSE"
      fi
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
    HB_CLIENT_AUTO_START=1
  else
    HB_CLIENT_AUTO_START=0
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

  if [[ ! "$CHOICE" == "U1" && ! "$CHOICE" == "U2" && ! "$CHOICE" == "U3" ]]; then
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
  else
    if [ "$CHOICE" == "U1" ]; then
        GATEWAY_IMAGE_NAME="fun-hb-client-and-hb-gateway"
    elif [ "$CHOICE" == "U2" ]; then
        GATEWAY_IMAGE_NAME="hb-client-and-hb-gateway"
    elif [ "$CHOICE" == "U3"  ]; then
        GATEWAY_IMAGE_NAME="all-apps"
    else
      echo
      echo "      ERROR: Unable to set Gateway image name correctly."
    fi
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

  if [[ ! "$CHOICE" == "U1" && ! "$CHOICE" == "U2" && ! "$CHOICE" == "U3" ]]; then
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
  else
    if [ "$CHOICE" == "U1" ]; then
        GATEWAY_CONTAINER_NAME="fun-hb-client-and-hb-gateway"
    elif [ "$CHOICE" == "U2" ]; then
        GATEWAY_CONTAINER_NAME="hb-client-and-hb-gateway"
    elif [ "$CHOICE" == "U3"  ]; then
        GATEWAY_CONTAINER_NAME="all-apps"
    else
      echo
      echo "      ERROR: Unable to set Gateway container name correctly."
    fi
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
  if [[ "$CHOICE" == 3 || "$CHOICE" == "U2" ]]; then
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
    GATEWAY_AUTO_START=1
  else
    GATEWAY_AUTO_START=0
  fi

  GATEWAY_CONF_FOLDER="$GATEWAY_FOLDER/conf"
  GATEWAY_LOGS_FOLDER="$GATEWAY_FOLDER/logs"
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
  echo "   [i] You chose 'Yes'"
elif [[ "$RESPONSE" == "0" ]]; then
  clear
  ./configure
  exit 0
else
  INDIVIDUAL_CONTAINERS="False"
  echo
  echo "   [i] You chose 'No'"
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
    clear
    echo
    echo "   CHOOSE WHICH INSTALLATION YOU WOULD LIKE TO DO:"
    echo
    echo "   [1] FUNTTASTIC HUMMINGBOT CLIENT and HUMMINGBOT GATEWAY [RECOMMENDED]"
    echo "   [2] HUMMINGBOT CLIENT and HUMMINGBOT GATEWAY"
    echo "   [3] ALL"
    echo
    echo "   [0] RETURN TO MAIN MENU"
    echo "   [exit] STOP SCRIPT EXECUTION"
    echo
    echo "   For more information about the FUNTTASTIC HUMMINGBOT CLIENT, please visit:"
    echo
    echo "         https://www.funttastic.com/partners/kujira"
    echo

    read -rp "   Enter your choice (1-3): " CHOICE

    while true; do
      case $CHOICE in
          1|2|3|0)
              break
              ;;
          *)
              echo
              echo "   [!] Invalid Input. Enter a number between 1 and 3."
              echo
              ;;
      esac

      read -rp "   Enter your choice (1-3): " CHOICE
    done

    case $CHOICE in
        1)
            CHOICE="U1"
            pre_installation_fun_hb_client
            pre_installation_hb_gateway
            ;;
        2)
            CHOICE="U2"
            pre_installation_hb_client
            pre_installation_hb_gateway
            ;;
        3)
            CHOICE="U3"
            pre_installation_fun_hb_client
            pre_installation_hb_gateway
            pre_installation_hb_client
            ;;
        0)
            clear
            ./configure
            ;;
        "exit")
            echo
            echo
            echo "      The script will close automatically in 2 seconds..."
            echo
            sleep 2
            exit 0
            ;;
    esac
  fi
else
  # Default settings to install Funttastic Hummingbot Client, Hummingbot Gateway and Hummingbot Client

  # Funttastic Hummingbot Client Settings
  FUN_HB_CLIENT_IMAGE_NAME=${FUN_HB_CLIENT_IMAGE_NAME:-"fun-hb-client"}
  FUN_HB_CLIENT_CONTAINER_NAME=${FUN_HB_CLIENT_CONTAINER_NAME:-"fun-hb-client"}
  FUN_HB_CLIENT_FOLDER_SUFFIX=${FUN_HB_CLIENT_FOLDER_SUFFIX:-"funttastic"}
  FUN_HB_CLIENT_FOLDER="$SHARED_FOLDER"/"$FUN_HB_CLIENT_FOLDER_SUFFIX"
  FUN_HB_CLIENT_PORT=${FUN_HB_CLIENT_PORT:-5000}
  FUN_HB_CLIENT_BUILD_CACHE=${FUN_HB_CLIENT_BUILD_CACHE:-"--no-cache"}
  FUN_HB_CLIENT_REPOSITORY_URL=${FUN_HB_CLIENT_REPOSITORY_URL:-"https://github.com/funttastic/fun-hb-client.git"}
  FUN_HB_CLIENT_REPOSITORY_BRANCH=${FUN_HB_CLIENT_REPOSITORY_BRANCH:-"community"}
  FUN_HB_CLIENT_AUTO_START=${FUN_HB_CLIENT_AUTO_START:-1}
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
  HB_CLIENT_AUTO_START=${HB_CLIENT_AUTO_START:-1}

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
  GATEWAY_AUTO_START=${GATEWAY_AUTO_START:-1}

  UNIFIED_IMAGE_NAME_CHOICE_1="fun-hb-client-and-hb-gateway"
  UNIFIED_IMAGE_NAME_CHOICE_2="hb-client-and-hb-gateway"
  UNIFIED_IMAGE_NAME_CHOICE_3="all-apps"
  UNIFIED_CONTAINER_NAME_CHOICE_1="$UNIFIED_IMAGE_NAME_CHOICE_1"
  UNIFIED_CONTAINER_NAME_CHOICE_2="$UNIFIED_IMAGE_NAME_CHOICE_2"
  UNIFIED_CONTAINER_NAME_CHOICE_3="$UNIFIED_IMAGE_NAME_CHOICE_3"

  # Settings for both
  TAG=${TAG:-"latest"}
  ENTRYPOINT=${ENTRYPOINT:-"/bin/bash"}

	RANDOM_PASSPHRASE=$(generate_passphrase 32)
fi

RESOURCES_FOLDER="$FUN_HB_CLIENT_FOLDER/client/resources"
SELECTED_PASSPHRASE=${RANDOM_PASSPHRASE:-$DEFINED_PASSPHRASE}
if [[ "$SSH_PUBLIC_KEY" && "$SSH_PRIVATE_KEY" ]]; then
    FUN_HB_CLIENT_REPOSITORY_URL="git@github.com:funttastic/fun-hb-client.git"
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

docker_create_image_fun_hb_client () {
  if [ ! "$FUN_HB_CLIENT_BUILD_CACHE" == "" ]
  then
    BUILT=$(DOCKER_BUILDKIT=1 docker build \
    "$FUN_HB_CLIENT_BUILD_CACHE" \
    --build-arg SSH_PUBLIC_KEY="$SSH_PUBLIC_KEY" \
    --build-arg SSH_PRIVATE_KEY="$SSH_PRIVATE_KEY" \
    --build-arg REPOSITORY_URL="$FUN_HB_CLIENT_REPOSITORY_URL" \
    --build-arg REPOSITORY_BRANCH="$FUN_HB_CLIENT_REPOSITORY_BRANCH" \
    -t "$FUN_HB_CLIENT_IMAGE_NAME" -f ./all/Dockerfile/fun-hb-client/Dockerfile .)
  fi
}

docker_create_container_fun_hb_client () {
  $BUILT \
  && docker run \
    -dit \
    --log-opt max-size=10m \
    --log-opt max-file=5 \
    --name "$FUN_HB_CLIENT_CONTAINER_NAME" \
    --network "$NETWORK" \
    --mount type=bind,source="$RESOURCES_FOLDER",target=/root/resources \
    --mount type=bind,source="$CERTS_FOLDER",target=/root/resources/certificates \
    --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
    -e RESOURCES_FOLDER="/root/resources" \
    -e CERTS_FOLDER="/root/resources/certificates" \
    -e PORT="$FUN_HB_CLIENT_PORT" \
    --entrypoint="$ENTRYPOINT" \
    "$FUN_HB_CLIENT_IMAGE_NAME":$TAG
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

unified_docker_create_image_choice_one () {
  if [[ ! "$FUN_HB_CLIENT_BUILD_CACHE" == "" || ! "$GATEWAY_BUILD_CACHE" == ""  ]]
  then
    BUILT=$(DOCKER_BUILDKIT=1 docker build \
    --build-arg CHOICE="$CHOICE" \
    --build-arg SSH_PUBLIC_KEY="$SSH_PUBLIC_KEY" \
    --build-arg SSH_PRIVATE_KEY="$SSH_PRIVATE_KEY" \
    --build-arg FUN_HB_CLIENT_REPOSITORY_URL="$FUN_HB_CLIENT_REPOSITORY_URL" \
    --build-arg FUN_HB_CLIENT_REPOSITORY_BRANCH="$FUN_HB_CLIENT_REPOSITORY_BRANCH" \
    --build-arg GATEWAY_REPOSITORY_URL="$GATEWAY_REPOSITORY_URL" \
    --build-arg GATEWAY_REPOSITORY_BRANCH="$GATEWAY_REPOSITORY_BRANCH" \
    -t "$UNIFIED_IMAGE_NAME_CHOICE_1" -f ./all/Dockerfile/unified/Dockerfile .)
  fi
}

unified_docker_create_container_choice_one () {
  $BUILT \
  && docker run \
    -dit \
    --log-opt max-size=10m \
    --log-opt max-file=5 \
    --name "$UNIFIED_CONTAINER_NAME_CHOICE_1" \
    --network "$NETWORK" \
    --mount type=bind,source="$RESOURCES_FOLDER",target=/root/funttastic/client/resources \
    --mount type=bind,source="$CERTS_FOLDER",target=/root/funttastic/client/resources/certificates \
    --mount type=bind,source="$GATEWAY_CONF_FOLDER",target=/root/hummingbot/gateway/conf \
    --mount type=bind,source="$GATEWAY_LOGS_FOLDER",target=/root/hummingbot/gateway/logs \
    --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
    -e RESOURCES_FOLDER="/root/funttastic/client/resources" \
    -e CERTS_FOLDER="/root/funttastic/client/resources/certificates" \
    -e CONF_FOLDER="/root/hummingbot/gateway/conf" \
    -e LOGS_FOLDER="/root/hummingbot/gateway/logs" \
    -e FUN_HB_CLIENT_PORT="$FUN_HB_CLIENT_PORT" \
    -e GATEWAY_PORT="$GATEWAY_PORT" \
    -e FUN_HB_CLIENT_COMMAND="$FUN_HB_CLIENT_COMMAND" \
    -e GATEWAY_COMMAND="$GATEWAY_COMMAND" \
    --entrypoint="$ENTRYPOINT" \
    "$UNIFIED_IMAGE_NAME_CHOICE_1":$TAG

#    --mount type=bind,source="$CERTS_FOLDER",target=/root/hummingbot/gateway/certs \
#    -e CERTS_FOLDER="/root/funttastic/client/resources/certificates" \
#    --mount type=bind,source="$CERTS_FOLDER",target=/root/funttastic/client/resources/certificates \
#    -e CERTS_FOLDER="/root/funttastic/client/resources/certificates" \
}

unified_docker_create_image_choice_two () {
  if [[ ! "$HB_CLIENT_BUILD_CACHE" == "" || ! "$GATEWAY_BUILD_CACHE" == ""  ]]
  then
    BUILT=$(DOCKER_BUILDKIT=1 docker build \
    --build-arg CHOICE="$CHOICE" \
    --build-arg SSH_PUBLIC_KEY="$SSH_PUBLIC_KEY" \
    --build-arg SSH_PRIVATE_KEY="$SSH_PRIVATE_KEY" \
    --build-arg HB_CLIENT_REPOSITORY_URL="$HB_CLIENT_REPOSITORY_URL" \
    --build-arg HB_CLIENT_REPOSITORY_BRANCH="$HB_CLIENT_REPOSITORY_BRANCH" \
    --build-arg GATEWAY_REPOSITORY_URL="$GATEWAY_REPOSITORY_URL" \
    --build-arg GATEWAY_REPOSITORY_BRANCH="$GATEWAY_REPOSITORY_BRANCH" \
    -t "$UNIFIED_IMAGE_NAME_CHOICE_2" -f ./all/Dockerfile/unified/Dockerfile .)
  fi
}

unified_docker_create_container_choice_two () {
  $BUILT \
  && docker run \
    -dit \
    --log-opt max-size=10m \
    --log-opt max-file=5 \
    --name "$UNIFIED_CONTAINER_NAME_CHOICE_2" \
    --network "$NETWORK" \
    --mount type=bind,source="$HB_CLIENT_CONF_FOLDER",target=/root/hummingbot/client/conf/connectors \
    --mount type=bind,source="$HB_CLIENT_LOGS_FOLDER",target=/root/hummingbot/client/logs \
    --mount type=bind,source="$HB_CLIENT_DATA_FOLDER",target=/root/hummingbot/client/data \
    --mount type=bind,source="$HB_CLIENT_SCRIPTS_FOLDER",target=/root/hummingbot/client/scripts \
    --mount type=bind,source="$HB_CLIENT_PMM_SCRIPTS_FOLDER",target=/root/hummingbot/client/pmm_scripts \
    --mount type=bind,source="$CERTS_FOLDER",target=/root/hummingbot/gateway/certs \
    --mount type=bind,source="$GATEWAY_CONF_FOLDER",target=/root/hummingbot/gateway/conf \
    --mount type=bind,source="$GATEWAY_LOGS_FOLDER",target=/root/hummingbot/gateway/logs \
    --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
    -e HB_CLIENT_LOGS_FOLDER="/root/hummingbot/client/logs" \
    -e HB_CLIENT_DATA_FOLDER="/root/hummingbot/client/data" \
    -e HB_CLIENT_SCRIPTS_FOLDER="/root/hummingbot/client/scripts" \
    -e HB_CLIENT_PMM_SCRIPTS_FOLDER="/root/hummingbot/client/pmm_scripts" \
    -e RESOURCES_FOLDER="/root/funttastic/client/resources" \
    -e CERTS_FOLDER="/root/hummingbot/gateway/certs" \
    -e CONF_FOLDER="/root/hummingbot/gateway/conf" \
    -e LOGS_FOLDER="/root/hummingbot/gateway/logs" \
    -e FUN_HB_CLIENT_PORT="$FUN_HB_CLIENT_PORT" \
    -e GATEWAY_PORT="$GATEWAY_PORT" \
    -e GATEWAY_COMMAND="$GATEWAY_COMMAND" \
    -e HB_CLIENT_COMMAND="$HB_CLIENT_COMMAND" \
    --entrypoint="$ENTRYPOINT" \
    "$UNIFIED_IMAGE_NAME_CHOICE_2":$TAG

#    --mount type=bind,source="$CERTS_FOLDER",target=/root/hummingbot/client/certs \
#    -e CERTS_FOLDER="/root/hummingbot/client/certs" \
}

unified_docker_create_image_choice_three () {
  if [[ ! "$FUN_HB_CLIENT_BUILD_CACHE" == "" || ! "$HB_CLIENT_BUILD_CACHE" == "" || ! "$GATEWAY_BUILD_CACHE" == ""  ]]
  then
    BUILT=$(DOCKER_BUILDKIT=1 docker build \
    --build-arg CHOICE="$CHOICE" \
    --build-arg SSH_PUBLIC_KEY="$SSH_PUBLIC_KEY" \
    --build-arg SSH_PRIVATE_KEY="$SSH_PRIVATE_KEY" \
    --build-arg FUN_HB_CLIENT_REPOSITORY_URL="$FUN_HB_CLIENT_REPOSITORY_URL" \
    --build-arg FUN_HB_CLIENT_REPOSITORY_BRANCH="$FUN_HB_CLIENT_REPOSITORY_BRANCH" \
    --build-arg HB_CLIENT_REPOSITORY_URL="$HB_CLIENT_REPOSITORY_URL" \
    --build-arg HB_CLIENT_REPOSITORY_BRANCH="$HB_CLIENT_REPOSITORY_BRANCH" \
    --build-arg GATEWAY_REPOSITORY_URL="$GATEWAY_REPOSITORY_URL" \
    --build-arg GATEWAY_REPOSITORY_BRANCH="$GATEWAY_REPOSITORY_BRANCH" \
    -t "$UNIFIED_IMAGE_NAME_CHOICE_3" -f ./all/Dockerfile/unified/Dockerfile .)
  fi
}

unified_docker_create_container_choice_three () {
  $BUILT \
  && docker run \
    -dit \
    --log-opt max-size=10m \
    --log-opt max-file=5 \
    --name "$UNIFIED_CONTAINER_NAME_CHOICE_3" \
    --network "$NETWORK" \
    --mount type=bind,source="$RESOURCES_FOLDER",target=/root/funttastic/client/resources \
    --mount type=bind,source="$HB_CLIENT_CONF_FOLDER",target=/root/hummingbot/client/conf/connectors \
    --mount type=bind,source="$HB_CLIENT_LOGS_FOLDER",target=/root/hummingbot/client/logs \
    --mount type=bind,source="$HB_CLIENT_DATA_FOLDER",target=/root/hummingbot/client/data \
    --mount type=bind,source="$HB_CLIENT_SCRIPTS_FOLDER",target=/root/hummingbot/client/scripts \
    --mount type=bind,source="$HB_CLIENT_PMM_SCRIPTS_FOLDER",target=/root/hummingbot/client/pmm_scripts \
    --mount type=bind,source="$CERTS_FOLDER",target=/root/hummingbot/gateway/certs \
    --mount type=bind,source="$GATEWAY_CONF_FOLDER",target=/root/hummingbot/gateway/conf \
    --mount type=bind,source="$GATEWAY_LOGS_FOLDER",target=/root/hummingbot/gateway/logs \
    --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
    -e RESOURCES_FOLDER="/root/funttastic/client/resources" \
    -e HB_CLIENT_LOGS_FOLDER="/root/hummingbot/client/logs" \
    -e HB_CLIENT_DATA_FOLDER="/root/hummingbot/client/data" \
    -e HB_CLIENT_SCRIPTS_FOLDER="/root/hummingbot/client/scripts" \
    -e HB_CLIENT_PMM_SCRIPTS_FOLDER="/root/hummingbot/client/pmm_scripts" \
    -e RESOURCES_FOLDER="/root/funttastic/client/resources" \
    -e CERTS_FOLDER="/root/hummingbot/gateway/certs" \
    -e CONF_FOLDER="/root/hummingbot/gateway/conf" \
    -e LOGS_FOLDER="/root/hummingbot/gateway/logs" \
    -e FUN_HB_CLIENT_PORT="$FUN_HB_CLIENT_PORT" \
    -e GATEWAY_PORT="$GATEWAY_PORT" \
    -e FUN_HB_CLIENT_COMMAND="$FUN_HB_CLIENT_COMMAND" \
    -e GATEWAY_COMMAND="$GATEWAY_COMMAND" \
    -e HB_CLIENT_COMMAND="$HB_CLIENT_COMMAND" \
    --entrypoint="$ENTRYPOINT" \
    "$UNIFIED_IMAGE_NAME_CHOICE_3":$TAG

#    --mount type=bind,source="$CERTS_FOLDER",target=/root/funttastic/client/resources/certificates \
#    -e CERTS_FOLDER="/root/funttastic/client/resources/certificates" \
#    --mount type=bind,source="$CERTS_FOLDER",target=/root/hummingbot/client/certs \
#    -e CERTS_FOLDER="/root/hummingbot/client/certs" \
}

post_installation_fun_hb_client () {
  APP_PATH_PREFIX="/root"

  if [[ "$CHOICE" == "U1" || "$CHOICE" == "U2" || "$CHOICE" == "U3" ]]; then
    APP_PATH_PREFIX="/root/funttastic/client"
  fi

  docker exec "$FUN_HB_CLIENT_CONTAINER_NAME" /bin/bash -c "echo '$SELECTED_PASSPHRASE' > $APP_PATH_PREFIX/selected_passphrase.txt"

  docker exec "$FUN_HB_CLIENT_CONTAINER_NAME" /bin/bash -c "cp -r $APP_PATH_PREFIX/resources_temp/* $APP_PATH_PREFIX/resources"
  docker exec "$FUN_HB_CLIENT_CONTAINER_NAME" /bin/bash -c "rm -rf $APP_PATH_PREFIX/resources_temp"
  docker exec "$FUN_HB_CLIENT_CONTAINER_NAME" /bin/bash -c "source /root/.bashrc > /dev/null 2>&1 && conda install click > /dev/null 2>&1" &
  docker exec "$FUN_HB_CLIENT_CONTAINER_NAME" /bin/bash -c "pip install -r /root/funttastic/client/requirements.txt"
  docker exec "$FUN_HB_CLIENT_CONTAINER_NAME" /bin/bash -c 'python '$APP_PATH_PREFIX'/resources/scripts/generate_ssl_certificates.py --passphrase "$(cat '$APP_PATH_PREFIX'/selected_passphrase.txt)" --cert-path '$APP_PATH_PREFIX'/resources/certificates'
  docker exec "$FUN_HB_CLIENT_CONTAINER_NAME" /bin/bash -c 'sed -i "s/<password>/"$(cat '$APP_PATH_PREFIX'/selected_passphrase.txt)"/g" '$APP_PATH_PREFIX'/resources/configuration/production.yml'
  docker exec "$FUN_HB_CLIENT_CONTAINER_NAME" /bin/bash -c "sed -i -e '/telegram:/,/enabled: true/ s/enabled: true/enabled: false/' -e '/telegram:/,/listen_commands: true/ s/listen_commands: true/listen_commands: false/' $APP_PATH_PREFIX/resources/configuration/common.yml"
  docker exec "$FUN_HB_CLIENT_CONTAINER_NAME" /bin/bash -c "sed -i -e '/logging:/,/use_telegram: true/ s/use_telegram: true/use_telegram: false/' -e '/telegram:/,/enabled: true/ s/enabled: true/enabled: false/' -e '/telegram:/,/listen_commands: true/ s/listen_commands: true/listen_commands: false/' $APP_PATH_PREFIX/resources/configuration/production.yml"
  docker exec "$FUN_HB_CLIENT_CONTAINER_NAME" /bin/bash -c "groupadd -f $GROUP"
#  docker exec "$FUN_HB_CLIENT_CONTAINER_NAME" /bin/bash -c "cd $APP_PATH_PREFIX/resources && chown -RH :$GROUP ."
#  docker exec "$FUN_HB_CLIENT_CONTAINER_NAME" /bin/bash -c "cd $APP_PATH_PREFIX/resources && chmod -R a+rwX ."

  if [ "$FUN_HB_CLIENT_AUTO_START" == 1 ]; then
    docker exec "$FUN_HB_CLIENT_CONTAINER_NAME" /bin/bash -c "python '$APP_PATH_PREFIX'/app.py" > /dev/null 2>&1 &
  fi

  if [ -n "$RANDOM_PASSPHRASE" ]; then
    docker exec "$FUN_HB_CLIENT_CONTAINER_NAME" /bin/bash -c 'echo "$(cat '$APP_PATH_PREFIX'/selected_passphrase.txt)" > '$APP_PATH_PREFIX'/resources/random_passphrase.txt' &> /dev/null
  fi

#  docker exec "$FUN_HB_CLIENT_CONTAINER_NAME" /bin/bash -c "rm -f selected_passphrase.txt"
}

post_installation_hb_client () {
  PY_PATH_PREFIX="/root"

  if [[ "$CHOICE" == "U1" || "$CHOICE" == "U2" || "$CHOICE" == "U3" ]]; then
    if [ -n "$UNIFIED_IMAGE_NAME_CHOICE_1" ]; then
      HB_CLIENT_CONTAINER_NAME="$UNIFIED_CONTAINER_NAME_CHOICE_1"
    elif [ -n "$UNIFIED_IMAGE_NAME_CHOICE_2" ]; then
      HB_CLIENT_CONTAINER_NAME="$UNIFIED_CONTAINER_NAME_CHOICE_2"
    else
      HB_CLIENT_CONTAINER_NAME="$UNIFIED_CONTAINER_NAME_CHOICE_3"
    fi
    PY_PATH_PREFIX="/root/hummingbot/client"
  fi

  if [ "$HB_CLIENT_AUTO_START" == 1 ]; then
    docker exec -it "$HB_CLIENT_CONTAINER_NAME" /bin/bash -c "/root/miniconda3/envs/hummingbot/bin/python3 $PY_PATH_PREFIX/bin/hummingbot_quickstart.py"
  fi
}

post_installation_hb_gateway () {
  APP_PATH_PREFIX="/root"

  if [[ "$CHOICE" == "U1" || "$CHOICE" == "U2" || "$CHOICE" == "U3" ]]; then
    APP_PATH_PREFIX="/root/hummingbot/gateway"
  fi

  docker exec "$GATEWAY_CONTAINER_NAME" /bin/bash -c "groupadd -f $GROUP"
  docker exec "$GATEWAY_CONTAINER_NAME" /bin/bash -c "cd $APP_PATH_PREFIX/conf && chown -RH :$GROUP ."
  docker exec "$GATEWAY_CONTAINER_NAME" /bin/bash -c "cd $APP_PATH_PREFIX/conf && chmod -R a+rw ."
  docker exec "$GATEWAY_CONTAINER_NAME" /bin/bash -c "cd $APP_PATH_PREFIX/logs && chown -RH :$GROUP ."
  docker exec "$GATEWAY_CONTAINER_NAME" /bin/bash -c "cd $APP_PATH_PREFIX/logs && chmod -R a+rw ."

  if [[ "$CHOICE" == "U1" || "$CHOICE" == "U2" || "$CHOICE" == "U3" ]]; then
      docker exec "$GATEWAY_CONTAINER_NAME" /bin/bash -c "ln -fs /root/funttastic/client/resources/certificates/* $APP_PATH_PREFIX/certs"
  fi

  if [ "$GATEWAY_AUTO_START" == 1 ]; then
    docker exec "$GATEWAY_CONTAINER_NAME" /bin/bash -c "cd $APP_PATH_PREFIX && yarn start --passphrase=$SELECTED_PASSPHRASE" > /dev/null 2>&1 &
  fi
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

unified_default_installation () {
  mkdir -p "$SHARED_FOLDER"
  mkdir -p "$CERTS_FOLDER"

  mkdir -p "$RESOURCES_FOLDER"

  mkdir -p "$GATEWAY_FOLDER"
  mkdir -p "$GATEWAY_CONF_FOLDER"
  mkdir -p "$GATEWAY_LOGS_FOLDER"

  chmod a+rw "$GATEWAY_CONF_FOLDER"

  unified_docker_create_image_choice_one
  unified_docker_create_container_choice_one

  if [ "$FUN_HB_CLIENT_AUTO_START" == 1 ]; then
    post_installation_fun_hb_client
  fi

  if [ "$GATEWAY_AUTO_START" == 1 ]; then
    post_installation_hb_gateway
  fi
}

unified_choice_two_installation () {
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

  mkdir -p "$GATEWAY_FOLDER"
  mkdir -p "$GATEWAY_CONF_FOLDER"
  mkdir -p "$GATEWAY_LOGS_FOLDER"

  chmod a+rw "$GATEWAY_CONF_FOLDER"

  unified_docker_create_image_choice_two
  unified_docker_create_container_choice_two

  if [ "$GATEWAY_AUTO_START" == 1 ]; then
    post_installation_hb_gateway
  fi

  if [ "$HB_CLIENT_AUTO_START" == 1 ]; then
    post_installation_hb_client
  fi
}

unified_choice_three_installation () {
  mkdir -p "$SHARED_FOLDER"
  mkdir -p "$CERTS_FOLDER"

  mkdir -p "$RESOURCES_FOLDER"

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

  unified_docker_create_image_choice_three
  unified_docker_create_container_choice_three

  if [ "$FUN_HB_CLIENT_AUTO_START" == 1 ]; then
    post_installation_fun_hb_client
  fi

  if [ "$GATEWAY_AUTO_START" == 1 ]; then
    post_installation_hb_gateway
  fi

  if [ "$HB_CLIENT_AUTO_START" == 1 ]; then
    post_installation_hb_client
  fi
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
        echo "   Installing:"
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
        ;;
    "U1")
        echo
        echo "   Installing:"
        echo
        echo "     > Funttastic Hummingbot Client"
        echo "     > Hummingbot Gateway"
        echo
        echo "     [i] Both in just one container."
        echo

        unified_default_installation
        ;;
    "U2")
        echo
        echo "   Installing:"
        echo
        echo "     > Hummingbot Client"
        echo "     > Hummingbot Gateway"
        echo
        echo "     [i] Both in just one container."
        echo

        unified_choice_two_installation
        ;;
    "U3")
        echo
        echo "   Installing:"
        echo
        echo "     > Funttastic Hummingbot Client"
        echo "     > Hummingbot Client"
        echo "     > Hummingbot Gateway"
        echo
        echo "     [i] All in just one container."
        echo

        unified_choice_three_installation
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
  printf "%25s %5s\n" "Version:"              "$TAG"
  printf "%25s %5s\n" "Base:"                 "$SHARED_FOLDER"
  printf "%25s %5s\n" "Common:"               "$COMMON_FOLDER"
  printf "%25s %5s\n" "Certificates:"         "$CERTS_FOLDER"
  printf "%25s %5s\n" "Entrypoint:"    				"$ENTRYPOINT"
  echo

  if [[ "$CHOICE" == 1 || "$CHOICE" == 4 || "$CHOICE" == 5 || "$CHOICE" == "U1" || "$CHOICE" == "U3" ]]; then

    if [[ "$CHOICE" == "U1" || "$CHOICE" == "U2" || "$CHOICE" == "U3" ]]; then
      FUN_HB_CLIENT_IMAGE_NAME="$UNIFIED_IMAGE_NAME_CHOICE_1"
      FUN_HB_CLIENT_CONTAINER_NAME="$UNIFIED_CONTAINER_NAME_CHOICE_1"
    fi

    echo
    echo "ℹ️  Confirm below if the Funttastic Hummingbot Client instance and its folders are correct:"
    echo
    printf "%25s %5s\n" "Image:"              	"$FUN_HB_CLIENT_IMAGE_NAME:$TAG"
    printf "%25s %5s\n" "Instance:"        			"$FUN_HB_CLIENT_CONTAINER_NAME"
    printf "%25s %5s\n" "Repository url:"       "$FUN_HB_CLIENT_REPOSITORY_URL"
    printf "%25s %5s\n" "Repository branch:"    "$FUN_HB_CLIENT_REPOSITORY_BRANCH"
    printf "%25s %5s\n" "Exposed port:"					"$FUN_HB_CLIENT_PORT"
    printf "%25s %5s\n" "Reuse image?:"    		  "$FUN_HB_CLIENT_BUILD_CACHE"
    printf "%25s %5s\n" "Autostart:"    		    "$FUN_HB_CLIENT_AUTO_START"
    echo
    printf "%25s %5s\n" "Fun HB Client folder:" "$FUN_HB_CLIENT_FOLDER"
    printf "%25s %5s\n" "Resources folder:"     "$RESOURCES_FOLDER"
    echo
  fi

  if [[ "$CHOICE" == 2 || "$CHOICE" == 5 || "$CHOICE" == "U2" || "$CHOICE" == "U3" ]]; then

    if [[ "$CHOICE" == "U1" || "$CHOICE" == "U2" || "$CHOICE" == "U3" ]]; then
      HB_CLIENT_IMAGE_NAME="$UNIFIED_IMAGE_NAME_CHOICE_2"
      HB_CLIENT_CONTAINER_NAME="$UNIFIED_CONTAINER_NAME_CHOICE_2"
    fi

    echo
    echo "ℹ️  Confirm below if the Hummingbot Client instance and its folders are correct:"
    echo
    printf "%25s %5s\n" "Image:"              	"$HB_CLIENT_IMAGE_NAME:$TAG"
    printf "%25s %5s\n" "Instance:"        			"$HB_CLIENT_CONTAINER_NAME"
    printf "%25s %5s\n" "Repository url:"       "$HB_CLIENT_REPOSITORY_URL"
    printf "%25s %5s\n" "Repository branch:"    "$HB_CLIENT_REPOSITORY_BRANCH"
    printf "%25s %5s\n" "Reuse image?:"    		  "$HB_CLIENT_BUILD_CACHE"
    printf "%25s %5s\n" "Autostart:"    		    "$HB_CLIENT_AUTO_START"
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
    if [[ "$CHOICE" == "U1" || "$CHOICE" == "U2" || "$CHOICE" == "U3" ]]; then
      if [ -n "$UNIFIED_IMAGE_NAME_CHOICE_1" ]
      then
        GATEWAY_IMAGE_NAME="$UNIFIED_IMAGE_NAME_CHOICE_1"
        GATEWAY_CONTAINER_NAME="$UNIFIED_CONTAINER_NAME_CHOICE_1"
      elif [  -n "$UNIFIED_IMAGE_NAME_CHOICE_2"  ]; then
        GATEWAY_IMAGE_NAME="$UNIFIED_IMAGE_NAME_CHOICE_2"
        GATEWAY_CONTAINER_NAME="$UNIFIED_CONTAINER_NAME_CHOICE_2"
      else
        GATEWAY_IMAGE_NAME="$UNIFIED_IMAGE_NAME_CHOICE_3"
        GATEWAY_CONTAINER_NAME="$UNIFIED_CONTAINER_NAME_CHOICE_3"
      fi
    fi

    echo
    echo "ℹ️  Confirm below if the Hummingbot Gateway instance and its folders are correct:"
    echo
    printf "%25s %5s\n" "Image:"              	"$GATEWAY_IMAGE_NAME:$TAG"
    printf "%25s %5s\n" "Instance:"        			"$GATEWAY_CONTAINER_NAME"
    printf "%25s %5s\n" "Exposed port:"					"$GATEWAY_PORT"
    printf "%25s %5s\n" "Repository url:"       "$GATEWAY_REPOSITORY_URL"
    printf "%25s %5s\n" "Repository branch:"    "$GATEWAY_REPOSITORY_BRANCH"
    printf "%25s %5s\n" "Reuse image?:"    		  "$GATEWAY_BUILD_CACHE"
    printf "%25s %5s\n" "Autostart:"    		    "$GATEWAY_AUTO_START"
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
