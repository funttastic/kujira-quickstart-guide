#!/bin/bash

# Function to check if a container exists
container_exists() {
    if [ "$(docker ps -a -q -f name=^/"$1"$)" ]; then
        return 0
    else
        echo "Container $1 does not exist."
        return 1
    fi
}

# Function to get container name from the user
get_container_name() {
    local container_var_name=$1
    local skip_keyword="skip"

    # Using indirect variable reference to get the value of the container variable
    local current_value=${!container_var_name}

    while true; do
        read -p "Enter the container name for $container_var_name [Type '$skip_keyword' to bypass or press Enter to use '$current_value']: " input_name
        if [ "$input_name" == "$skip_keyword" ]; then
            echo "Skipping restart for $container_var_name."
            declare -g $container_var_name="$skip_keyword"
            return 1
        elif [ -z "$input_name" ] && [ -n "$current_value" ]; then
            # If the user presses enter and a name is already set, use the existing name
            declare -g $container_var_name="$current_value"
            break
        elif [ -n "$input_name" ]; then
            if container_exists "$input_name"; then
                declare -g $container_var_name="$input_name"
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

    docker stop -t 1 "$container_name" && sleep 1 && docker inspect -f '{{.State.Running}}' "$container_name" | grep "true" && docker kill "$container_name"
    docker start "$container_name"
    docker exec "$container_name" /bin/bash -c "$exec_command" > /dev/null 2>&1 &
}

# Specific functions to restart containers
restart_fun_hb_client() {
    get_container_name FUN_HB_CLIENT_CONTAINER_NAME
    restart_container "$FUN_HB_CLIENT_CONTAINER_NAME" "python app.py"
}

restart_hb_client() {
    get_container_name HB_CLIENT_CONTAINER_NAME
    restart_container "$HB_CLIENT_CONTAINER_NAME" "/root/miniconda3/envs/hummingbot/bin/python3 /root/bin/hummingbot_quickstart.py"
}

restart_hb_gateway() {
    get_container_name HB_GATEWAY_CONTAINER_NAME
    restart_container "$HB_GATEWAY_CONTAINER_NAME" "yarn start"
}

# Function to restart all containers
restart_all() {
    restart_fun_hb_client
    restart_hb_client
    restart_hb_gateway
}

# Function to choose which container to restart
choose() {
    echo
    echo "   ===============     WELCOME TO FUNTTASTIC HUMMINGBOT CLIENT SETUP     ==============="
    echo
    echo "   CHOOSE WHICH CONTAINERS AND SERVICES YOU WOULD LIKE TO RESTART:"
    echo
    echo "   [1] ALL"
    echo "   [2] FUNTTASTIC HUMMINGBOT CLIENT"
    echo "   [3] HUMMINGBOT CLIENT"
    echo "   [4] HUMMINGBOT GATEWAY"
    echo
    echo "   [0] RETURN TO MAIN MENU"
    echo
    echo "   For more information about the FUNTTASTIC HUMMINGBOT CLIENT, please visit:"
    echo
    echo "         https://www.funttastic.com/partners/kujira"
    echo

    read -p "   Enter your choice (1-4): " CHOICE

    while true; do
        case $CHOICE in
            1)
                restart_all
                break
                ;;
            2)
                restart_fun_hb_client
                break
                ;;
            3)
                restart_hb_client
                break
                ;;
            4)
                restart_hb_gateway
                break
                ;;
            0)
                ./configure
                break
                ;;
            *)
                echo "   Invalid Input. Enter a number between 1 and 4."
                read -p "   Enter your choice (1-4): " CHOICE
                ;;
        esac
    done
}

# =====================================================================================================================

choose
