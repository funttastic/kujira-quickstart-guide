#!/bin/bash

echo
echo
echo "===============  CREATE A NEW HUMMINGBOT GATEWAY INSTANCE ==============="
echo
echo
echo "ℹ️  Press [ENTER] for default values:"
echo

if [ ! "$DEBUG" == "" ]
then
	docker stop temp-hb-gateway
	docker rm temp-hb-gateway
	docker rmi temp-hb-gateway
	docker commit hummingbot-gateway temp-hb-gateway
fi

CUSTOMIZE=$1

# Customize the Gateway image to be used?
if [ "$CUSTOMIZE" == "--customize" ]
then
  # Specify hummingbot image
  RESPONSE="$IMAGE_NAME"
  if [ "$RESPONSE" == "" ]
  then
    read -p "   Enter Hummingbot image you want to use (default = \"hummingbot-gateway\") >>> " RESPONSE
  fi
  if [ "$RESPONSE" == "" ]
  then
    IMAGE_NAME="hummingbot-gateway"
  else
    IMAGE_NAME="$RESPONSE"
  fi

  # Specify a Hummingbot version?
  RESPONSE="$TAG"
  if [ "$RESPONSE" == "" ]
  then
    read -p "   Enter Hummingbot version you want to use [latest/development] (default = \"latest\") >>> " RESPONSE
  fi
  if [ "$RESPONSE" == "" ]
  then
   TAG="latest"
  else
    TAG=$RESPONSE
  fi

  # Create a new Gateway image?
  RESPONSE="$BUILD_CACHE"
  if [ "$RESPONSE" == "" ]
  then
    read -p "   Do you want to use an existing Hummingbot Gateway image (\"y/N\") >>> " RESPONSE
  fi
  if [[ "$RESPONSE" == "N" || "$RESPONSE" == "n" || "$RESPONSE" == "" ]]
  then
    echo "   A new image will be created..."
    BUILD_CACHE="--no-cache"
  else
    BUILD_CACHE=""
  fi

  # Create a new Gateway instance?
  RESPONSE="$INSTANCE_NAME"
  if [ "$RESPONSE" == "" ]
  then
    read -p "   Enter a name for your new Hummingbot Gateway instance (default = \"hummingbot-gateway\") >>> " RESPONSE
  fi
  if [ "$RESPONSE" == "" ]
  then
    INSTANCE_NAME="hummingbot-gateway"
  else
    INSTANCE_NAME=$RESPONSE
  fi

  # Location to save files?
  RESPONSE="$FOLDER"
  if [ "$RESPONSE" == "" ]
  then
    FOLDER_SUFFIX="shared"
    read -p "   Enter a folder path where do you want your Hummingbot Gateway files to be saved (default = \"$FOLDER_SUFFIX\") >>> " RESPONSE
  fi
  if [ "$RESPONSE" == "" ]
  then
    FOLDER=$PWD/$FOLDER_SUFFIX
  elif [[ ${RESPONSE::1} != "/" ]]; then
    FOLDER=$PWD/$RESPONSE
  else
    FOLDER=$RESPONSE
  fi

  # Gateawu exposed port?
  RESPONSE="$PORT"
  if [ "$RESPONSE" == "" ]
  then
    read -p "   Enter a port for expose your new Hummingbot Gateway (default = \"15888\") >>> " RESPONSE
  fi
  if [ "$RESPONSE" == "" ]
  then
    PORT=15888
  else
    PORT=$RESPONSE
  fi

  # Prompts user for a password for gateway certificates
  RESPONSE="$GATEWAY_PASSPHRASE"
  while [ "$RESPONSE" == "" ]
  do
    read -sp "   Define a passphrase for the Gateway certificate  >>> " RESPONSE
    echo "   It is necessary to define a password for the certificate, which is the same as the one entered when executing the \"gateway generate-certs\" command on the client. Try again."
  done
  GATEWAY_PASSPHRASE=$RESPONSE
else
	if [ ! "$DEBUG" == "" ]
	then
		IMAGE_NAME="temp-hb-gateway"
		TAG="latest"
		BUILD_CACHE="--no-cache"
		INSTANCE_NAME="temp-hb-gateway"
		FOLDER_SUFFIX="shared"
		FOLDER=$PWD/$FOLDER_SUFFIX
		PORT=15888
		ENTRYPOINT="--entrypoint=/bin/bash"
	else
		IMAGE_NAME="hummingbot-gateway"
		TAG="latest"
		BUILD_CACHE="--no-cache"
		INSTANCE_NAME="hummingbot-gateway"
		FOLDER_SUFFIX="shared"
		FOLDER=$PWD/$FOLDER_SUFFIX
		PORT=15888
  fi

  # Prompts user for a password for gateway certificates
  while [ "$GATEWAY_PASSPHRASE" == "" ]
  do
    read -sp "   Define a passphrase for the Gateway certificate  >>> " GATEWAY_PASSPHRASE
    echo "   It is necessary to define a password for the certificate, which is the same as the one entered when executing the \"gateway generate-certs\" command on the client. Try again."
  done
fi

CERTS_FOLDER="$FOLDER/common/certs"
CONF_FOLDER="$FOLDER/gateway/conf"
LOGS_FOLDER="$FOLDER/gateway/logs"

echo
echo "ℹ️  Confirm below if the instance and its folders are correct:"
echo
printf "%30s %5s\n" "Instance name:" "$INSTANCE_NAME"
printf "%30s %5s\n" "Version:" "hummingbot/hummingbot:$TAG"
echo
printf "%30s %5s\n" "Main folder:" "$FOLDER"
printf "%30s %5s\n" "Cert files:" "├── $CERTS_FOLDER"
printf "%30s %5s\n" "Gateway config files:" "└── $CONF_FOLDER"
printf "%30s %5s\n" "Gateway log files:" "└── $LOGS_FOLDER"
printf "%30s %5s\n" "Gateway exposed port:" "└── $PORT"
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
  echo "Creating Hummingbot instance ..."
  echo
  # 1) Create main folder for your new gateway instance
  mkdir -p $FOLDER
  # 2) Create subfolders for hummingbot files
  mkdir -p $CERTS_FOLDER
  mkdir -p $CONF_FOLDER
  mkdir -p $LOGS_FOLDER

  # 3) Set required permissions to save hummingbot password the first time
  chmod a+rw $CONF_FOLDER

  # 4) Create a new image for gateway
  BUILT=true
  if [ ! "$BUILD_CACHE" == "" ]
  then
    BUILT=$(DOCKER_BUILDKIT=1 docker build $BUILD_CACHE -t $IMAGE_NAME -f gateway/Dockerfile .)
  fi

  # 5) Launch a new gateway instance of hummingbot
  $BUILT && docker run \
    -it \
    --log-opt max-size=10m \
    --log-opt max-file=5 \
    -p $PORT:15888 \
    --name $INSTANCE_NAME \
    --network host \
    --mount type=bind,source=$CERTS_FOLDER,target=/root/certs \
    --mount type=bind,source=$CONF_FOLDER,target=/root/conf \
    --mount type=bind,source=$LOGS_FOLDER,target=/root/logs \
    --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
    -e CERTS_FOLDER="/root/certs" \
    -e CONF_FOLDER="/root/conf" \
    -e LOGS_FOLDER="/root/logs" \
    -e GATEWAY_PASSPHRASE="$GATEWAY_PASSPHRASE" \
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
