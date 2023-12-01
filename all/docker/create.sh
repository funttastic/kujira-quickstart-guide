#!/bin/bash

CUSTOMIZE=$1
USER=$(whoami)
GROUP=$(id -gn)
TAG="latest"

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

install_kujira_hb_client () {
  # Customize the Client image to be used?
  RESPONSE="$IMAGE_NAME"
  if [ "$RESPONSE" == "" ]
  then
    echo
    read -p "   Enter a Kujira HB Client image name you want to use (default = \"kujira-hb-client\") >>> " RESPONSE
  fi
  if [ "$RESPONSE" == "" ]
  then
    IMAGE_NAME="kujira-hb-client"
  else
    IMAGE_NAME="$RESPONSE"
  fi

  # Create a new image?
  RESPONSE="$BUILD_CACHE"
  if [ "$RESPONSE" == "" ]
  then
    echo
    read -p "   Do you want to use an existing Kujira HB Client image (\"y/N\") >>> " RESPONSE
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
  RESPONSE="$INSTANCE_NAME"
  if [ "$RESPONSE" == "" ]
  then
    echo
    read -p "   Enter a name for your new Kujira HB Client instance (default = \"kujira-hb-client\") >>> " RESPONSE
  fi
  if [ "$RESPONSE" == "" ]
  then
    INSTANCE_NAME="kujira-hb-client"
  else
    INSTANCE_NAME=$RESPONSE
  fi

  # Prompt the user for the passphrase to encrypt the certificates
  while true; do
      echo
      read -s -p "   Enter a passphrase to encrypt the certificates with at least 4 characters >>> " DEFINED_PASSPHRASE
      if [ -z "$DEFINED_PASSPHRASE" ] || [ ${#DEFINED_PASSPHRASE} -lt 4 ]; then
          echo
          echo
          echo "      Weak passphrase, please try again."
      else
          echo
          break
      fi
  done

  # Location to save files?
  RESPONSE="$FOLDER"
  if [ "$RESPONSE" == "" ]
  then
    FOLDER_SUFFIX="shared"
    echo
    read -p "   Enter a folder name where your Kujira HB Client files will be saved (default = \"$FOLDER_SUFFIX\") >>> " RESPONSE
  fi
  if [ "$RESPONSE" == "" ]
  then
    FOLDER=$PWD/$FOLDER_SUFFIX
  elif [[ ${RESPONSE::1} != "/" ]]; then
    FOLDER=$PWD/$RESPONSE
  else
    FOLDER=$RESPONSE
  fi
}

echo
echo "   ===============  WELCOME TO KUJIRA HB CLIENT SETUP ==============="
echo

RESPONSE=""
read -p "   Do you want to automate the entire process,
   including setting a random passphrase? [Y/n] >>> " RESPONSE
if [[ "$RESPONSE" == "Y" || "$RESPONSE" == "y" || "$RESPONSE" == "" ]]
then
  echo
else
  CUSTOMIZE="--customize"
fi

if [ "$CUSTOMIZE" == "--customize" ]
then
  echo
  echo "ℹ️  Press [ENTER] for default values:"
  echo

  echo "   CHOOSE A OPTION BELOW TO INSTALL"
  echo
  echo "   [1] KUJIRA HB CLIENT"
  echo "   [3] HUMMINGBOT CLIENT FORK"
  echo "   [2] HUMMINGBOT GATEWAY FORK"
  echo "   [4] KUJIRA HB CLIENT and HB GATEWAY FORK [DEFAULT]"
  echo "   [5] ALL"
  echo
  echo "   For more information about the difference between HB Official and HB Forks, please visit:"
  echo
  echo "         https://wwww.site.com/docs"
  echo

  read -p "   Enter your choice (1-5): " choice

#  if [[ -z $choice || ! $choice =~ ^[1-5]$ ]]; then
#      choice=4
#  fi

  while true; do
    case $choice in
        1|2|3|4|5)
            break
            ;;
        *)
            echo "   Invalid Input. Enter a number between 1 and 5."
            ;;
    esac

    read -p "   Enter your choice (1-5): " choice
  done

  case $choice in
      1)
          echo
          echo
          echo "   ===============  KUJIRA HB CLIENT INSTALLATION PROCESS ==============="
          echo
          install_kujira_hb_client
          ;;
      2)
          NOT_IMPLEMENTED=true
          echo
          echo
          echo "      NOT IMPLEMENTED"
          echo
          ;;
      3)
          NOT_IMPLEMENTED=true
          echo
          echo
          echo "      NOT IMPLEMENTED"
          echo
          ;;
      4)
          NOT_IMPLEMENTED=true
          echo
          echo
          echo "      NOT IMPLEMENTED"
          echo
          ;;
      5)
          NOT_IMPLEMENTED=true
          echo
          echo
          echo "      NOT IMPLEMENTED"
          echo
          ;;
  esac
else
  # Default settings to install Kujira HB Client and HB Gateway Fork

  # Kujira HB Client Settings
  IMAGE_NAME="kujira-hb-client"
  INSTANCE_NAME="kujira-hb-client"

  # HB Gateway Fork Settings

  # Settings for both
  TAG="latest"
  BUILD_CACHE="--no-cache"
  FOLDER_SUFFIX="shared"
  FOLDER=$PWD/$FOLDER_SUFFIX

	RANDOM_PASSPHRASE=$(generate_passphrase 32)
fi

RESOURCES_FOLDER="$FOLDER/kujira/client/resources"

if [ -n "$RANDOM_PASSPHRASE" ]; then  \
echo "   ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"; \
echo "   |                                                        |"; \
echo "   |   A new random passphrase has been saved in the file   |"; \
echo "   |                                                        |"; \
echo "   |      resources/random_passphrase.txt                   |"; \
echo "   |                                                        |"; \
echo "   |   Copy it to a safe location and delete the file.      |"; \
echo "   |                                                        |"; \
echo "   ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"; \
echo; \
fi

docker_create_image_kujira_hb_client () {
  if [ ! "$BUILD_CACHE" == "" ]
  then
    BUILT=$(DOCKER_BUILDKIT=1 docker build \
    --build-arg RANDOM_PASSPHRASE="$RANDOM_PASSPHRASE" \
    $BUILD_CACHE \
    --build-arg DEFINED_PASSPHRASE="$DEFINED_PASSPHRASE" \
    -t $IMAGE_NAME -f ./docker/Dockerfile .)
  fi
}

docker_create_container_kujira_hb_client () {
  $BUILT \
  && docker run \
    -it \
    --log-opt max-size=10m \
    --log-opt max-file=5 \
    --name $INSTANCE_NAME \
    --network host \
    -v "$RESOURCES_FOLDER":/root/app/resources \
    --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
    -e RESOURCES_FOLDER="/root/app/resources" \
    -e HOST_USER_GROUP="$GROUP" \
    $IMAGE_NAME:$TAG
}

default_installation () {
  BUILT=true

  $BUILT && docker volume create resources > /dev/null

  # Create a new separated image for Kujira HB Client
  docker_create_image_kujira_hb_client

  # Create a new separated container from image
  docker_create_container_kujira_hb_client
}

create_instance () {
  echo
  echo "   Automatically installing:"
  echo
  echo "     > Kujira HB Client"
  echo "     > Hummingbot Gateway Fork"
  echo
  mkdir -p "$FOLDER"
  mkdir -p "$RESOURCES_FOLDER"

  default_installation
}

install_docker () {
  if [ "$(command -v docker)" ]; then
    create_instance
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

        create_instance
    else
      echo
      echo "   Script execution aborted."
      echo
    fi
  fi
}

if [[ "$CUSTOMIZE" == "--customize" && "$NOT_IMPLEMENTED" == 0 ]]
then
  echo
  echo "ℹ️  Confirm below if the instance and its folders are correct:"
  echo
  printf "%19s %5s\n" "Instance name:" "$INSTANCE_NAME"
  printf "%19s %5s\n" "Version:" "$TAG"
  printf "%19s %5s\n" "Main folder:" "├── $FOLDER"
  printf "%19s %5s\n" "Resources folder:" "├── $RESOURCES_FOLDER"
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
    install_docker
  fi
fi
