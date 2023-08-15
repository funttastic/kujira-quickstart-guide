#!/bin/bash

echo
echo
echo "===============  CREATE A NEW FUNTTASTIC CLIENT INSTANCE ==============="
echo
echo
echo "ℹ️  Press [ENTER] for default values:"
echo

if [ ! "$DEBUG" == "" ]
then
	docker stop temp-fun-hb-client
	docker rm temp-fun-hb-client
	docker rmi temp-fun-hb-client
	docker commit fun-hb-client temp-fun-hb-client
fi

CUSTOMIZE=$1

# Customize the image to be used?
if [ "$CUSTOMIZE" == "--customize" ]
then
  RESPONSE="$IMAGE_NAME"
  if [ "$RESPONSE" == "" ]
  then
    read -p "   Enter the image you want to use (default = \"fun-hb-client\") >>> " RESPONSE
  fi
  if [ "$RESPONSE" == "" ]
  then
    IMAGE_NAME="fun-hb-client"
  else
    IMAGE_NAME="$RESPONSE"
  fi

  # Specify a version?
  RESPONSE="$TAG"
  if [ "$RESPONSE" == "" ]
  then
    read -p "   Enter the version you want to use [latest/development] (default = \"latest\") >>> " TAG
  fi
  if [ "$RESPONSE" == "" ]
  then
    TAG="latest"
  else
    TAG=$RESPONSE
  fi

  # Create a new image?
  RESPONSE="$BUILD_CACHE"
  if [ "$RESPONSE" == "" ]
  then
    read -p "   Do you want to use an existing image (\"y/N\") >>> " RESPONSE
  fi
  if [[ "$RESPONSE" == "N" || "$RESPONSE" == "n" || "$RESPONSE" == "" ]]
  then
    echo "   A new image will be created..."
    BUILD_CACHE="--no-cache"
  else
    BUILD_CACHE=""
  fi

  # Create a new instance?
  RESPONSE="$INSTANCE_NAME"
  if [ "$RESPONSE" == "" ]
  then
    read -p "   Enter a name for your new Funttastic Client instance (default = \"fun-hb-client\") >>> " RESPONSE
  fi
  if [ "$RESPONSE" == "" ]
  then
    INSTANCE_NAME="fun-hb-client"
  else
    INSTANCE_NAME=$RESPONSE
  fi

  # Location to save files?
  RESPONSE="$FOLDER"
  if [ "$RESPONSE" == "" ]
  then
    FOLDER_SUFFIX="shared"
    read -p "   Enter a folder name where your files will be saved (default = \"$FOLDER_SUFFIX\") >>> " RESPONSE
  fi
  if [ "$RESPONSE" == "" ]
  then
    FOLDER=$PWD/$FOLDER_SUFFIX
  elif [[ ${RESPONSE::1} != "/" ]]; then
    FOLDER=$PWD/$RESPONSE
  else
    FOLDER=$RESPONSE
  fi

  RESPONSE="$CLONE_BRANCH"
  if [ "$RESPONSE" == "" ]
  then
    read -p "   Enter the branch to be cloned from the repository (default = \"production\") >>> " RESPONSE
  fi
  if [ "$RESPONSE" == "" ]
  then
    CLONE_BRANCH="production"
  else
    CLONE_BRANCH="$RESPONSE"
  fi
else
	if [ ! "$DEBUG" == "" ]
	then
		IMAGE_NAME="temp-fun-hb-client"
		TAG="latest"
		BUILD_CACHE="--no-cache"
		INSTANCE_NAME="temp-fun-hb-client"
		FOLDER_SUFFIX="shared"
		FOLDER=$PWD/$FOLDER_SUFFIX
		ENTRYPOINT="--entrypoint=/bin/bash"
		CLONE_BRANCH=${CLONE_BRANCH:-production}
	else
		IMAGE_NAME="fun-hb-client"
		TAG="latest"
		BUILD_CACHE="--no-cache"
		INSTANCE_NAME="fun-hb-client"
		FOLDER_SUFFIX="shared"
		FOLDER=$PWD/$FOLDER_SUFFIX
		CLONE_BRANCH=${CLONE_BRANCH:-production}
	fi
fi

COMMON_FOLDER="$FOLDER/common"
CERTIFICATES_FOLDER="$COMMON_FOLDER/certificates"
CLIENT_FOLDER="$FOLDER/funttastic/client"
RESOURCES_FOLDER="$CLIENT_FOLDER/resources"
CONFIGURATION_FOLDER="$RESOURCES_FOLDER/configuration"
STRATEGIES_FOLDER="$RESOURCES_FOLDER/strategies"
LOGS_FOLDER="$RESOURCES_FOLDER/logs"

echo
echo "ℹ️  Confirm below if the instance and its folders are correct:"
echo
printf "%30s %5s\n" "Instance name:" "$INSTANCE_NAME"
printf "%30s %5s\n" "Version:" "$TAG"
printf "%30s %5s\n" "Repository branch:" "$CLONE_BRANCH"
echo
printf "%30s %5s\n" "Base folder:"    " $FOLDER"
printf "%30s %5s\n" "Common folder:"  " $COMMON_FOLDER"
printf "%30s %5s\n" "Certificates:"   " $CERTIFICATES_FOLDER"
printf "%30s %5s\n" "Client folder:"  " $CLIENT_FOLDER"
printf "%30s %5s\n" "Resources:"      " $RESOURCES_FOLDER"
printf "%30s %5s\n" "Configuration:"  " $CONFIGURATION_FOLDER"
printf "%30s %5s\n" "Strategies:"     " $STRATEGIES_FOLDER"
printf "%30s %5s\n" "Log files:"      " $LOGS_FOLDER"
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
  echo "Creating instance..."
  echo
  # 1) Create main folder for your new instance
  mkdir -p $FOLDER
  # 2) Create subfolders
  mkdir -p RESOURCES_FOLDER
  mkdir -p CERTIFICATES_FOLDER
  mkdir -p CONFIGURATION_FOLDER
  mkdir -p STRATEGIES_FOLDER
  mkdir -p LOGS_FOLDER

  # 4) Create a new image
  BUILT=true
  if [ ! "$BUILD_CACHE" == "" ]
  then
    BUILT=$(DOCKER_BUILDKIT=1 docker build $BUILD_CACHE -t $IMAGE_NAME -f funttastic/client/Dockerfile .)
  fi

  # 5) Launch a new instance
  $BUILT \
  && docker run \
    -it \
    --log-opt max-size=10m \
    --log-opt max-file=5 \
    --name $INSTANCE_NAME \
    --network host \
    --mount type=bind,source=$RESOURCES_FOLDER,target=/root/resources \
    -e RESOURCES_FOLDER="/root/resources" \
    -e CLONE_BRANCH="$CLONE_BRANCH" \
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
