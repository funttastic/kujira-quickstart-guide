#!/bin/bash

SCRIPT_DIR=$(dirname "$0")
SCRIPT_NAME="$(basename "$0")"
SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT_NAME"

LOCAL_HOST_URL_PREFIX="http://localhost"

main_menu() {
	clear
	echo
	echo "   ===============     WELCOME TO FUNTTASTIC CLIENT SETUP     ==============="
	echo
	echo "   CHOOSE WHICH ACTION YOU WOULD LIKE TO DO:"
	echo
	echo "   [1] INSTALL"
	echo "   [2] RESTART"
	echo "   [3] CLIENT"
	echo
	echo "   [exit] EXIT"
	echo
	more_information
	echo

	read -p "   Enter your choice (1, 2, 3, or exit): " CHOICE

	while true; do
		case $CHOICE in
		1)
			./scripts/install.sh
			break
			;;
		2)
			./scripts/restart.sh
			break
			;;
		3)
			./scripts/actions.sh
			break
			;;
		"exit")
			exit_application
			;;
		*)
			echo
			echo "      ❌ Invalid Input. Enter a your choice (1, 2, 3) or type exit."
			echo
			read -p "   Enter your choice (1, 2, 3, or exit): " CHOICE
			;;
		esac
	done
}

show_title() {
	local title="$1"

	clear
	echo
	echo "   ===========================   $title   ==========================="
	echo
}

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
	filter_containers

	show_title

	while true; do
		if [ -n "$CONTAINER_NAME" ]; then
			echo "   Enter the container name (was found: \"$CONTAINER_NAME\")"

			echo
			echo "   [Press Enter to use '$CONTAINER_NAME' or enter 'back' to return to the previous menu]"
			echo
		else
			echo "   Enter the container name (example: \"fun-kuji-hb\"):"
			echo
		fi

		read -rp "   >>> " input_name

		if [ "$input_name" == "exit" ]; then
			exit_application
		elif [ "$input_name" == "back" ]; then
			CONTAINER_NAME="back"
			echo
			echo "   ⚠️  Returning to the previous menu..."
			return 1
		elif [ -n "$CONTAINER_NAME" ]; then
			while true; do
				if [ -z "$input_name" ]; then
					# In this case, the name of the container defined in the CONTAINER_NAME variable will be used.
					# A valid container name was found by the 'filter_containers' function and added to this variable CONTAINER_NAME
					return 0
				else
					if container_exists "$input_name"; then
						CONTAINER_NAME="$input_name"
						return 0
					else
						echo
						echo "   ⚠️  Container not found! Please enter a valid container name or 'back' to exit."
						echo
					fi
				fi

				read -rp "   >>> " input_name

				if [ "$input_name" == "exit" ]; then
					exit_application
				elif [ "$input_name" == "back" ]; then
					echo
					echo "   ⚠️  Returning to the previous menu..."
					return 1
				fi
			done
		elif [ -z "$CONTAINER_NAME" ]; then
			while true; do
				if [ -z "$input_name" ]; then
					echo
					echo "   ⚠️  Please enter a container name or 'back' to return to previous menu."
					echo
				else
					if container_exists "$input_name"; then
						CONTAINER_NAME="$input_name"
						return 0
					else
						echo
						echo "   ⚠️  Container not found! Please enter a valid container name or 'back' to return to previous menu."
						echo
					fi
				fi

				read -rp "   >>> " input_name

				if [ "$input_name" == "exit" ]; then
					exit_application
				elif [ "$input_name" == "back" ]; then
					echo
					echo "   ⚠️  Returning to the previous menu..."
					return 1
				fi
			done
		fi
	done
}

restart_container() {
	local container_name=${1:-$CONTAINER_NAME}
	local post_restart_command=$2

	if [ "$container_name" == "back" ]; then
		return 0
	fi

	echo
	echo "      Stopping: $({
		docker stop -t 1 "$container_name" && sleep 1 &&
			if [ "$(docker inspect -f '{{.State.Running}}' "$container_name")" == "true" ]; then
				docker kill "$container_name"
			fi
	} 2>&1)"

	echo
	echo "      Starting: $(docker start "$container_name" 2>&1)"

	if [ -n "$post_restart_command" ]; then
		eval "$post_restart_command"
	fi
}

open_in_web_navigator() {
	urls=("$@")

	for url in "${urls[@]}"; do
		if [[ "$OSTYPE" == "linux-gnu"* ]]; then
			xdg-open "$url" &>/dev/null &
		elif [[ "$OSTYPE" == "darwin"* ]]; then
			open "$url" &>/dev/null &
		elif [[ "$OSTYPE" == "cygwin" ]]; then
			cmd.exe /c start "$url" &>/dev/null &
		elif [[ "$OSTYPE" == "msys" ]]; then
			cmd.exe /c start "$url" &>/dev/null &
		elif [[ "$OSTYPE" == "win32" ]]; then
			cmd.exe /c start "$url" &>/dev/null &
		fi
	done
}

more_information() {
	echo "   For more information about the FUNTTASTIC CLIENT, please visit:"
	echo
	echo "      https://www.funttastic.com/partners/kujira"
}

exit_application() {
	clear
	echo
	echo "      Feel free to come back whenever you want."
	echo
	more_information
	echo
	exit 0
}
