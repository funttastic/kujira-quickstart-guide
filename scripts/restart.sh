#!/bin/bash

SCRIPT_DIR=$(dirname "$0")
SCRIPT_NAME="$(basename "$0")"
SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT_NAME"

filter_containers() {
    # Getting the list of containers
    local containers

    containers=$(docker ps -a --format "{{.Names}}")

    # Filtering the containers
    for name in $containers; do
        # Checking if the name contains 'fun', 'kuji' and 'hb'
        if [[ $name =~ fun ]] && [[ $name =~ kuji ]] && [[ $name =~ hb ]] && [ -z "$CONTAINER_NAME" ]; then
            declare -g CONTAINER_NAME=$name
        fi
    done
}

container_exists() {
		if docker ps -a --format '{{.Names}}' | grep -q "^$1$"; then
        return 0
    else
    		# When the container does not exist
        return 1
    fi
}

get_container_name() {
    local skip_keyword="skip"
    local word

    filter_containers

    if [ -z "$CONTAINER_NAME" ]; then
				CONTAINER_NAME="fun-kuji-hb"
				word="default"
		else
				word="found"
    fi

    while true; do
        echo
        echo "   Enter the container name ($word = \"$CONTAINER_NAME\")"
        echo
        echo "   [Press Enter to use '$CONTAINER_NAME' or enter '$skip_keyword' to bypass]"
        echo

        read -rp "   >>> " input_name

				if [ "$input_name" == "$skip_keyword" ]; then
						CONTAINER_NAME="$skip_keyword"
						echo
						echo "   ⚠️  Skipping restarting..."
            return 1
				elif [ -z "$input_name" ]; then
				    return 0
				else
						if ! container_exists "$input_name"; then
								echo
								echo "   ⚠️  Container not found! Skipping restarting..."
								return 1
						fi

						CONTAINER_NAME="$input_name"

						return 0
				fi
    done
}

restart_container() {
    local container_name=${1:-$CONTAINER_NAME}
    local exec_command=$2

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

    if [ -n "$exec_command" ]; then
    		docker exec "$container_name" /bin/bash -c "$exec_command" > /dev/null 2>&1 &
    fi

}

restart() {
    if get_container_name; then
				restart_container "$CONTAINER_NAME" "docker attach"
    fi
}

more_information(){
  echo "   For more information about the FUNTTASTIC CLIENT, please visit:"
  echo
  echo "      https://www.funttastic.com/partners/kujira"
}

choose() {
    clear
    echo
    echo "   ===========================   DOCKER CONTAINERS RESTART   ==========================="
    echo
    echo "   CHOOSE WHICH SERVICES YOU WOULD LIKE TO RESTART:"
    echo
    echo "   [1] ALL SERVICES"
    echo
    echo "   [back] RETURN TO MAIN MENU"
    echo "   [exit] Exit"
    echo
    more_information
    echo

    read -rp "   Enter your choice (1, 2, 3, 4, back or exit): " CHOICE

    clear

    while true; do
        case $CHOICE in
            1)
                restart
                sleep 3
                clear
                exec "$SCRIPT_PATH"
                break
                ;;
            "back")
                ./configure
                break
                ;;
            "exit")
                echo
                echo "      Feel free to come back whenever you want."
                echo
                more_information
                echo
                exit 0
                ;;
            *)
                echo
                echo "      ❌ Invalid Input. Enter the choice [1] or back or exit."
                echo
                read -rp "   Enter your choice (1, back or exit): " CHOICE
                ;;
        esac
    done
}

choose
