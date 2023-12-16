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
	docker commit hb-client temp-hb-client
fi

CUSTOMIZE=$1

# Customize the image to be used?
if [ "$CUSTOMIZE" == "--customize" ]
then
  RESPONSE="$IMAGE_NAME"
  if [ "$RESPONSE" == "" ]
  then
    read -rp "   Enter the image you want to use (default = \"hb-client\") >>> " RESPONSE
  fi
  if [ "$RESPONSE" == "" ]
  then
    IMAGE_NAME="hb-client"
  else
    IMAGE_NAME="$RESPONSE"
  fi

  # Specify a version?
  RESPONSE="$TAG"
  if [ "$RESPONSE" == "" ]
  then
    read -rp "   Enter the version you want to use [latest/development] (default = \"latest\") >>> " TAG
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
    read -rp "   Do you want to use an existing image (\"y/N\") >>> " RESPONSE
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
    read -rp "   Enter a name for your new instance (default = \"hb-client\") >>> " RESPONSE
  fi
  if [ "$RESPONSE" == "" ]
  then
    INSTANCE_NAME="hb-client"
  else
    INSTANCE_NAME=$RESPONSE
  fi

  # Location to save files?
  RESPONSE="$FOLDER"
  if [ "$RESPONSE" == "" ]
  then
    FOLDER_SUFFIX="shared"
    read -rp "   Enter a folder name where your files will be saved (default = \"$FOLDER_SUFFIX\") >>> " RESPONSE
  fi
  if [ "$RESPONSE" == "" ]
  then
    FOLDER=$PWD/$FOLDER_SUFFIX
  elif [[ ${RESPONSE::1} != "/" ]]; then
    FOLDER=$PWD/$RESPONSE
  else
    FOLDER=$RESPONSE
  fi

  RESPONSE="$REPOSITORY_URL"
  if [ "$RESPONSE" == "" ]
  then
    read -rp "   Enter the url from the repository to be cloned (default = \"https://github.com/Team-Kujira/hummingbot.git\") >>> " RESPONSE
  fi
  if [ "$RESPONSE" == "" ]
  then
    REPOSITORY_URL="https://github.com/Team-Kujira/hummingbot.git"
  else
    REPOSITORY_URL="$RESPONSE"
  fi

  RESPONSE="$REPOSITORY_BRANCH"
  if [ "$RESPONSE" == "" ]
  then
    read -rp "   Enter the branch from the repository to be cloned (default = \"production\") >>> " RESPONSE
  fi
  if [ "$RESPONSE" == "" ]
  then
    REPOSITORY_BRANCH="production"
  else
    REPOSITORY_BRANCH="$RESPONSE"
  fi
else
	if [ ! "$DEBUG" == "" ]
	then
		IMAGE_NAME=${IMAGE_NAME:-temp-hb-client}
		TAG=${TAG:-latest}
		BUILD_CACHE=${BUILD_CACHE:---no-cache}
		INSTANCE_NAME=${INSTANCE_NAME:-temp-hb-client}
		FOLDER_SUFFIX=${FOLDER_SUFFIX:-shared}
		FOLDER=${FOLDER:-$PWD/$FOLDER_SUFFIX}
		ENTRYPOINT=${ENTRYPOINT:---entrypoint=/bin/bash}
		REPOSITORY_URL=${REPOSITORY_URL:-https://github.com/Team-Kujira/hummingbot.git}
		REPOSITORY_BRANCH=${REPOSITORY_BRANCH:-production}
	else
		IMAGE_NAME=${IMAGE_NAME:-hb-client}
		TAG=${TAG:-latest}
		BUILD_CACHE=${BUILD_CACHE:---no-cache}
		INSTANCE_NAME=${INSTANCE_NAME:-hb-client}
		FOLDER_SUFFIX=${FOLDER_SUFFIX:-shared}
		FOLDER=${FOLDER:-$PWD/$FOLDER_SUFFIX}
		REPOSITORY_URL=${REPOSITORY_URL:-https://github.com/Team-Kujira/hummingbot.git}
		REPOSITORY_BRANCH=${REPOSITORY_BRANCH:-production}
	fi
fi

COMMON_FOLDER="$FOLDER/common"
CERTS_FOLDER="$COMMON_FOLDER/certificates"
CLIENT_FOLDER="$FOLDER/hummingbot/client"
CONF_FOLDER="$CLIENT_FOLDER/conf"
LOGS_FOLDER="$CLIENT_FOLDER/logs"
DATA_FOLDER="$CLIENT_FOLDER/data"
SCRIPTS_FOLDER="$CLIENT_FOLDER/scripts"
PMM_SCRIPTS_FOLDER="$CLIENT_FOLDER/pmm_scripts"
COMMAND="/root/miniconda3/envs/hummingbot/bin/python3 /root/bin/hummingbot_quickstart.py"

echo
echo "ℹ️  Confirm below if the instance and its folders are correct:"
echo
printf "%30s %5s\n" "Image:"              	"$IMAGE_NAME:$TAG"
printf "%30s %5s\n" "Instance:"        			"$INSTANCE_NAME"
printf "%30s %5s\n" "Repository url:"       "$REPOSITORY_URL"
printf "%30s %5s\n" "Repository branch:"    "$REPOSITORY_BRANCH"
printf "%30s %5s\n" "Reuse image?:"    		  "$BUILD_CACHE"
printf "%30s %5s\n" "Debug?:"    						"$DEBUG"
printf "%30s %5s\n" "Entrypoint:"    				"$ENTRYPOINT"
echo
printf "%30s %5s\n" "Base:"                 "$FOLDER"
printf "%30s %5s\n" "Common:"               "$COMMON_FOLDER"
printf "%30s %5s\n" "Certificates:"         "$CERTS_FOLDER"
printf "%30s %5s\n" "Client:"               "$CLIENT_FOLDER"
printf "%30s %5s\n" "Config files:"         "$CONF_FOLDER"
printf "%30s %5s\n" "Log files:"            "$LOGS_FOLDER"
printf "%30s %5s\n" "Trade and data files:" "$DATA_FOLDER"
printf "%30s %5s\n" "PMM scripts files:"    "$PMM_SCRIPTS_FOLDER"
printf "%30s %5s\n" "Scripts files:"        "$SCRIPTS_FOLDER"
echo

prompt_proceed () {
  RESPONSE=""
  read -rp "   Do you want to proceed? [Y/n] >>> " RESPONSE
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
  mkdir -p "$FOLDER"
  mkdir -p "$CLIENT_FOLDER"
  # 2) Create subfolders for hummingbot files
  mkdir -p "$CONF_FOLDER"
  mkdir -p "$CONF_FOLDER"/connectors
  mkdir -p "$CONF_FOLDER"/strategies
  mkdir -p "$LOGS_FOLDER"
  mkdir -p "$DATA_FOLDER"
  mkdir -p "$PMM_SCRIPTS_FOLDER"
  mkdir -p "$CERTS_FOLDER"
  mkdir -p "$SCRIPTS_FOLDER"

  # 3) Set required permissions to save hummingbot password the first time
  chmod a+rw "$CONF_FOLDER"

  # 4) Create a new image?
  BUILT=true
  if [ ! "$BUILD_CACHE" == "" ]
  then
    BUILT=$(DOCKER_BUILDKIT=1 docker build "$BUILD_CACHE" --build-arg REPOSITORY_URL="$REPOSITORY_URL" --build-arg REPOSITORY_BRANCH="$REPOSITORY_BRANCH" -t "$IMAGE_NAME" -f ./all/Dockerfile/hb-client/Dockerfile .)
  fi

  # 5) Launch a new instance
cat <<EOF
$BUILT \
&& docker run \
	-dt \
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
	-e LOGS_FOLDER="/root/logs" \
	-e DATA_FOLDER="/root/data" \
	-e SCRIPTS_FOLDER="/root/scripts" \
	-e PMM_SCRIPTS_FOLDER="/root/pmm_scripts" \
	-e CERTS_FOLDER="/root/certs" \
	-e COMMAND=$COMMAND \
	$ENTRYPOINT \
	$IMAGE_NAME:$TAG
EOF

  $BUILT \
  && docker run \
		-dt \
    --log-opt max-size=10m \
    --log-opt max-file=5 \
    --name "$INSTANCE_NAME" \
    --network host \
    --mount type=bind,source="$CONF_FOLDER",target=/root/conf \
    --mount type=bind,source="$LOGS_FOLDER",target=/root/logs \
    --mount type=bind,source="$DATA_FOLDER",target=/root/data \
    --mount type=bind,source="$SCRIPTS_FOLDER",target=/root/scripts \
    --mount type=bind,source="$PMM_SCRIPTS_FOLDER",target=/root/pmm_scripts \
    --mount type=bind,source="$CERTS_FOLDER",target=/root/certs \
    --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
    -e CONF_FOLDER="/root/conf" \
    -e LOGS_FOLDER="/root/logs" \
    -e DATA_FOLDER="/root/data" \
    -e SCRIPTS_FOLDER="/root/scripts" \
    -e PMM_SCRIPTS_FOLDER="/root/pmm_scripts" \
    -e CERTS_FOLDER="/root/certs" \
    -e COMMAND="$COMMAND" \
    "$ENTRYPOINT" \
    "$IMAGE_NAME":"$TAG"
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
