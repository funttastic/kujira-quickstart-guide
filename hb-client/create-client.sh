#!/bin/bash

echo
echo
echo "===============  CREATE A NEW HUMMINGBOT CLIENT INSTANCE ==============="
echo
echo
echo "ℹ️  Press [ENTER] for default values:"
echo

if [ ! "$DEBUG" == "" ]
then
	docker stop temp-hb-client
	docker rm temp-hb-client
	docker rmi temp-hb-client
	docker commit hummingbot-client temp-hb-client
fi

CUSTOMIZE=$1

# Customize the Client image to be used?
if [ "$CUSTOMIZE" == "--customize" ]
then
  RESPONSE="$IMAGE_NAME"
  if [ "$RESPONSE" == "" ]
  then
    read -p "   Enter Hummingbot image you want to use (default = \"hummingbot-client\") >>> " RESPONSE
  fi
  if [ "$RESPONSE" == "" ]
  then
    IMAGE_NAME="hummingbot-client"
  else
    IMAGE_NAME="$RESPONSE"
  fi

  # Specify a Hummingbot version?
  RESPONSE="$TAG"
  if [ "$RESPONSE" == "" ]
  then
    read -p "   Enter Hummingbot version you want to use [latest/development] (default = \"latest\") >>> " TAG
  fi
  if [ "$RESPONSE" == "" ]
  then
    TAG="latest"
  else
    TAG=$RESPONSE
  fi

  # Create a new Client image?
  RESPONSE="$BUILD_CACHE"
  if [ "$RESPONSE" == "" ]
  then
    read -p "   Do you want to use an existing Hummingbot Client image (\"y/N\") >>> " RESPONSE
  fi
  if [[ "$RESPONSE" == "N" || "$RESPONSE" == "n" || "$RESPONSE" == "" ]]
  then
    echo "   A new image will be created..."
    BUILD_CACHE="--no-cache"
  else
    BUILD_CACHE=""
  fi

  # Create a new Client instance?
  RESPONSE="$INSTANCE_NAME"
  if [ "$RESPONSE" == "" ]
  then
    read -p "   Enter a name for your new Hummingbot instance (default = \"hummingbot-client\") >>> " RESPONSE
  fi
  if [ "$RESPONSE" == "" ]
  then
    INSTANCE_NAME="hummingbot-client"
  else
    INSTANCE_NAME=$RESPONSE
  fi

  # Location to save files?
  RESPONSE="$FOLDER"
  if [ "$RESPONSE" == "" ]
  then
    FOLDER_SUFFIX="shared"
    read -p "   Enter a folder name where your Hummingbot files will be saved (default = \"$FOLDER_SUFFIX\") >>> " RESPONSE
  fi
  if [ "$RESPONSE" == "" ]
  then
    FOLDER=$PWD/$FOLDER_SUFFIX
  elif [[ ${RESPONSE::1} != "/" ]]; then
    FOLDER=$PWD/$RESPONSE
  else
    FOLDER=$RESPONSE
  fi
else
	if [ ! "$DEBUG" == "" ]
	then
		IMAGE_NAME="temp-hb-client"
		TAG="latest"
		BUILD_CACHE="--no-cache"
		INSTANCE_NAME="temp-hb-client"
		FOLDER_SUFFIX="shared"
		FOLDER=$PWD/$FOLDER_SUFFIX
		ENTRYPOINT="--entrypoint=/bin/bash"
	else
		IMAGE_NAME="hummingbot-client"
		TAG="latest"
		BUILD_CACHE="--no-cache"
		INSTANCE_NAME="hummingbot-client"
		FOLDER_SUFFIX="shared"
		FOLDER=$PWD/$FOLDER_SUFFIX
	fi
fi

CONF_FOLDER="$FOLDER/client/conf"
LOGS_FOLDER="$FOLDER/client/logs"
DATA_FOLDER="$FOLDER/client/data"
SCRIPTS_FOLDER="$FOLDER/client/scripts"
PMM_SCRIPTS_FOLDER="$FOLDER/client/pmm_scripts"
CERTS_FOLDER="$FOLDER/common/certs"

echo
echo "ℹ️  Confirm below if the instance and its folders are correct:"
echo
printf "%30s %5s\n" "Instance name:" "$INSTANCE_NAME"
printf "%30s %5s\n" "Version:" "hummingbot/hummingbot:$TAG"
echo
printf "%30s %5s\n" "Main folder:" "$FOLDER"
printf "%30s %5s\n" "Config files:" "├── $CONF_FOLDER"
printf "%30s %5s\n" "Log files:" "├── $LOGS_FOLDER"
printf "%30s %5s\n" "Trade and data files:" "├── $DATA_FOLDER"
printf "%30s %5s\n" "PMM scripts files:" "├── $PMM_SCRIPTS_FOLDER"
printf "%30s %5s\n" "Scripts files:" "├── $SCRIPTS_FOLDER"
printf "%30s %5s\n" "Cert files:" "├── $CERTS_FOLDER"
echo

prompt_proceed () {
  RESPONSE=""
  read -p "   Do you want to proceed? [Y/n] >>> " RESPONSE
  if [[ "$RESPONSE" == "Y" || "$RESPONSE" == "y" || "$RESPONSE" == "" ]]
  then
    PROCEED="Y"
  fi
}

# Execute docker commands
create_instance () {
  echo
  echo "Creating Hummingbot instance..."
  echo
  # 1) Create main folder for your new instance
  mkdir -p $FOLDER
  # 2) Create subfolders for hummingbot files
  mkdir -p $CONF_FOLDER
  mkdir -p $CONF_FOLDER/connectors
  mkdir -p $CONF_FOLDER/strategies
  mkdir -p $LOGS_FOLDER
  mkdir -p $DATA_FOLDER
  mkdir -p $PMM_SCRIPTS_FOLDER
  mkdir -p $CERTS_FOLDER
  mkdir -p $SCRIPTS_FOLDER

  # 3) Set required permissions to save hummingbot password the first time
  chmod a+rw $CONF_FOLDER

  # 4) Create a new image for hummingbot
  BUILT=true
  if [ ! "$BUILD_CACHE" == "" ]
  then
    BUILT=$(DOCKER_BUILDKIT=1 docker build $BUILD_CACHE -t $IMAGE_NAME -f client/Dockerfile .)
  fi

  # 5) Launch a new gateway instance of hummingbot
  $BUILT \
  && docker run \
    -it \
    --log-opt max-size=10m \
    --log-opt max-file=5 \
    --name $INSTANCE_NAME \
    --network host \
    --mount type=bind,source=$CONF_FOLDER,target=/root/conf \
    --mount type=bind,source=$LOGS_FOLDER,target=/root/logs \
    --mount type=bind,source=$DATA_FOLDER,target=/root/data \
    --mount type=bind,source=$SCRIPTS_FOLDER,target=/root/scripts \
    --mount type=bind,source=$PMM_SCRIPTS_FOLDER,target=/root/pmm_scripts \
    --mount type=bind,source=$CERTS_FOLDER,target=/root/certs \
    --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
    -e CONF_FOLDER="/root/conf" \
    -e DATA_FOLDER="/root/data" \
    -e SCRIPTS_FOLDER="/root/scripts" \
    -e PMM_SCRIPTS_FOLDER="/root/pmm_scripts" \
    -e CERTS_FOLDER="/root/certs" \
    $ENTRYPOINT \
    $IMAGE_NAME:$TAG
}

if [ "$CUSTOMIZE" == "--customize" ]
then
  prompt_proceed
  if [[ "$PROCEED" == "Y" || "$PROCEED" == "y" ]]
  then
   create_instance
  else
   echo "   Aborted"
   echo
  fi
else
  create_instance
fi
