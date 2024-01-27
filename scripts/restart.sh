#!/bin/bash

DIR_NAME=$(dirname "$0")
SCRIPT_NAME="$(basename "$0")"
SCRIPT_RELATIVE_PATH="$DIR_NAME/$SCRIPT_NAME"

# Function to filter containers
filter_containers() {
    # Getting the list of containers
    local containers

    containers=$(docker ps -a --format "{{.Names}}")

    # Filtering the containers
    for name in $containers; do
        # Checking if the name contains 'fun' and 'client'
        if [[ $name =~ fun ]] && [[ $name =~ client ]] && [ -z "$FUN_CLIENT_CONTAINER_NAME" ]; then
            FUN_CLIENT_CONTAINER_NAME=$name
        fi

        # Checking if the name contains 'hb' and 'client', but not 'fun'
        if [[ $name =~ hb ]] && [[ $name =~ client ]] && ! [[ $name =~ fun ]] && [ -z "$HB_CLIENT_CONTAINER_NAME" ]; then
            HB_CLIENT_CONTAINER_NAME=$name
        fi

        # Checking if the name contains 'hb' and 'gateway'
        if [[ $name =~ hb ]] && [[ $name =~ gateway ]] && [ -z "$HB_GATEWAY_CONTAINER_NAME" ]; then
            HB_GATEWAY_CONTAINER_NAME=$name
        fi
    done
}

# Function to check if a container exists
container_exists() {
    if [ "$(docker ps -a -q -f name=^/"$1"$)" ]; then
        return 0
    else
        echo
        echo "      Container $1 does not exist."
        return 1
    fi
}

# Function to get container name from the user
get_container_name() {
    local container_var_name=$1
    local skip_keyword="skip"

    filter_containers

    # Using indirect variable reference to get the value of the container variable
    local current_value=${!container_var_name}

    if [ "$container_var_name" == "FUN_CLIENT_CONTAINER_NAME" ]; then
        app_name="FUNTTASTIC CLIENT"
        current_value="$FUN_CLIENT_CONTAINER_NAME"
    elif [ "$container_var_name" == "HB_CLIENT_CONTAINER_NAME" ]; then
        app_name="Hummingbot Client"
        current_value="$HB_CLIENT_CONTAINER_NAME"
    elif [ "$container_var_name" == "HB_GATEWAY_CONTAINER_NAME" ]; then
        app_name="Hummingbot Gateway"
        current_value="$HB_GATEWAY_CONTAINER_NAME"
    else
        app_name="$container_var_name"
    fi

    while true; do
        echo
        read -rp "   Enter the container name for $app_name
   [Type '$skip_keyword' to bypass or press Enter to use '$current_value']: " input_name
        if [ "$input_name" == "$skip_keyword" ]; then
            echo
            echo "      Skipping restart for $container_var_name."
            declare -g "$container_var_name"="$skip_keyword"
            return 1
        elif [ -z "$input_name" ] && [ -n "$current_value" ]; then
            # If the user presses enter and a name is already set, use the existing name
            declare -g "$container_var_name"="$current_value"
            break
        elif [ -n "$input_name" ]; then
            if container_exists "$input_name"; then
                declare -g "$container_var_name"="$input_name"
                break
            fi
        fi
    done
}

# General function to stop and restart a container
restart_container() {
    local container_name=$1
    local exec_command=$2

    # Check if the container restart was skipped
    if [ "$container_name" == "skip" ]; then
        return 0
    fi

    echo

    echo "      Stopping: $({
            docker stop -t 1 "$container_name" && sleep 1 && \
            if [ "$(docker inspect -f '{{.State.Running}}' "$container_name")" == "true" ]; then
                docker kill "$container_name"
            fi
        } 2>&1)"

    echo

    echo "      Starting: $(docker start "$container_name" 2>&1)"

    docker exec "$container_name" /bin/bash -c "$exec_command" > /dev/null 2>&1 &
}

authentication() {
    echo
    echo "   Please enter your SSL certificates passphrase"
    echo
    echo "   +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    echo "   | [i] This password was set during the Funttastic HB Client installation            |"
    echo "   |     or by running the 'gateway generate-certs' command in the Hummingbot Client   |"
    echo "   |     or during the Hummingbot Gateway installation if you installed it separately. |"
    echo "   +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    echo

    read -srp "   >>> " passphrase

    echo "$passphrase" > /dev/null 2>&1
}

# Specific functions to restart containers
restart_fun_client() {
    get_container_name FUN_CLIENT_CONTAINER_NAME

    if [ ! "$FUN_CLIENT_CONTAINER_NAME" == "skip" ]; then
        authentication
    fi

    restart_container "$FUN_CLIENT_CONTAINER_NAME" "python app.py $passphrase"
}

restart_hb_client() {
    get_container_name HB_CLIENT_CONTAINER_NAME
    restart_container "$HB_CLIENT_CONTAINER_NAME" "/root/miniconda3/envs/hummingbot/bin/python3 /root/bin/hummingbot_quickstart.py"
}

restart_hb_gateway() {
    get_container_name HB_GATEWAY_CONTAINER_NAME

    if [[ ! "$HB_GATEWAY_CONTAINER_NAME" == "skip" && ! "$CHOICE" == 1 ]]; then
        authentication
    fi
    
    restart_container "$HB_GATEWAY_CONTAINER_NAME" "yarn start --passphrase=$passphrase"
}

# Function to restart all containers
restart_all() {
    restart_fun_client
    restart_hb_client
    restart_hb_gateway
}

# Function to choose which container to restart
choose() {
    clear
    echo
    echo "   =====================     DOCKER CONTAINERS START / RESTART     ====================="
    echo
    echo "   CHOOSE WHICH CONTAINERS AND SERVICES YOU WOULD LIKE TO RESTART:"
    echo
    echo "   [1] ALL"
    echo "   [2] FUNTTASTIC CLIENT"
    echo "   [3] HUMMINGBOT CLIENT"
    echo "   [4] HUMMINGBOT GATEWAY"
    echo
    echo "   [0] RETURN TO MAIN MENU"
    echo "   [exit] STOP SCRIPT EXECUTION"
    echo
    echo "   For more information about the FUNTTASTIC CLIENT, please visit:"
    echo
    echo "         https://www.funttastic.com/partners/kujira"
    echo

    read -rp "   Enter your choice (1-4): " CHOICE

    clear

    while true; do
        case $CHOICE in
            1)
                restart_all
                sleep 3
                clear
                exec "$SCRIPT_RELATIVE_PATH"
                break
                ;;
            2)
                restart_fun_client
                sleep 3
                clear
                exec "$SCRIPT_RELATIVE_PATH"
                break
                ;;
            3)
                restart_hb_client
                sleep 3
                clear
                exec "$SCRIPT_RELATIVE_PATH"
                break
                ;;
            4)
                restart_hb_gateway
                sleep 3
                clear
                exec "$SCRIPT_RELATIVE_PATH"
                break
                ;;
            0)
                ./configure
                break
                ;;
            "exit")
                echo
                echo
                echo "      The script will close automatically in 3 seconds..."
                echo
                sleep 3
                exit 0
                ;;
            *)
                echo
                echo "   [!] Invalid Input. Enter a number between 1 and 4."
                echo
                read -rp "   Enter your choice (1-4): " CHOICE
                ;;
        esac
    done
}

# =====================================================================================================================

choose
