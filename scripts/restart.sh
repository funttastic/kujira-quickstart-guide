#!/bin/bash

SCRIPT_DIR=$(dirname "$0")
SCRIPT_NAME="$(basename "$0")"
SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT_NAME"

source "$SCRIPT_DIR/common.sh"

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

#			docker attach "$CONTAINER_NAME"
		fi
	fi
}

choose() {
	show_title "DOCKER CONTAINERS RESTART"

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
			main_menu
			break
			;;
		"exit")
			exit_application
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

# =====================================================================================================================

restart
main_menu
