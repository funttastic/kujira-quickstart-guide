#!/bin/bash

SCRIPT_DIR=$(dirname "$0")
SCRIPT_NAME="$(basename "$0")"
SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT_NAME"
LOCAL_HOST_URL_PREFIX="http://localhost"

show_title() {
	clear
	echo
	echo "   ===========================   DOCKER CONTAINERS RESTART   ==========================="
	echo
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
			exit 0
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
					exit 0
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
					exit 0
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

restart() {
	if get_container_name; then
		if restart_container "$CONTAINER_NAME"; then
			local FILEBROWSER_PORT
			local FUN_FRONTEND_PORT
			local FILEBROWSER_URL
			local FUN_FRONTEND_URL

			FILEBROWSER_PORT=$(docker exec "$CONTAINER_NAME" /bin/bash -c "grep 'FILEBROWSER_PORT=' /root/.bashrc | cut -d'=' -f2")
			FUN_FRONTEND_PORT=$(docker exec "$CONTAINER_NAME" /bin/bash -c "grep 'FRONTEND_PORT=' /root/.bashrc | cut -d'=' -f2")
			FILEBROWSER_URL="$LOCAL_HOST_URL_PREFIX:$FILEBROWSER_PORT"
			FUN_FRONTEND_URL="$LOCAL_HOST_URL_PREFIX:$FUN_FRONTEND_PORT"

			open_in_web_navigator "$FILEBROWSER_URL" "$FUN_FRONTEND_URL"

			#						docker attach "$CONTAINER_NAME"
		fi
	fi
}

more_information() {
	echo "   For more information about the FUNTTASTIC CLIENT, please visit:"
	echo
	echo "      https://www.funttastic.com/partners/kujira"
}

choose() {
	show_title

	echo "   CHOOSE WHICH SERVICES YOU WOULD LIKE TO RESTART:"
	echo
	echo "   [1] ALL SERVICES"
	echo
	echo "   [back] RETURN TO MAIN MENU"
	echo "   [exit] EXIT"
	echo
	more_information
	echo

	read -rp "   Enter your choice (1, back or exit): " CHOICE

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
			clear
			echo
			echo "      Feel free to come back whenever you want."
			echo
			more_information
			echo
			exit 0
			;;
		*)
			show_title
			echo "   ❌ Invalid Input. Enter the choice [1] or back or exit."
			echo
			read -rp "   Enter your choice (1, back or exit): " CHOICE
			;;
		esac
	done
}

choose
