#!/bin/bash

#SCRIPT_DIR=$(dirname "$0")
#SCRIPT_NAME="$(basename "$0")"
#SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT_NAME"

CUSTOMIZE=$1
USER=$(whoami)
GROUP=$(id -gn)
TAG="latest"
CHOICE=""
MIN_PASSPHRASE_LENGTH=4
ENTRYPOINT=""
NETWORK="bridge"
DEFAULT_WAITING_TIME=3

STRATEGY="pure_market_making"
VERSION="1.0.0"
ID="default"

# Inside the container
CERTIFICATES_FOLDER="/root/shared/common/certificates"

select_ssh_key() {
	local keys=()
	local key_paths=()
	for key in ~/.ssh/*; do
		# If this key is a public key, skip it.
		if [[ ${key} == *.pub ]]; then
			continue
		fi

		# If there is no corresponding .pub file, skip this key.
		if [[ ! -f "${key}.pub" ]]; then
			continue
		fi

		# This is a private key with a corresponding public key.
		keys+=("$(basename "${key}")")
		key_paths+=("${key}")
	done

	local count=${#keys[@]}

	echo "   Found $count private SSH keys:"
	echo

	for i in "${!keys[@]}"; do
		echo "      $(($i+1))) ${keys[i]}"
	done

	while true; do
		echo
		echo "   Select one of these keys or enter the absolute path of a key"
		echo
		read -rp "   >>> " REPLY

		if [[ "$REPLY" =~ ^[0-9]+$ ]] && [ 1 -le "$REPLY" ] && [ "$REPLY" -le "$count" ]; then
			echo
			echo "      ✅ You selected the key: ${key_paths[$REPLY-1]}"
			export SSH_PRIVATE_KEY_HOST_PATH="${key_paths[$REPLY-1]}"
			export SSH_PUBLIC_KEY_HOST_PATH="$SSH_PRIVATE_KEY_HOST_PATH.pub"
			break
		elif [[ "$REPLY" == /* || "$REPLY" == ~* ]]; then
				local expanded_reply="${REPLY/#\~/$HOME}"
				expanded_reply="${expanded_reply/#\~\//$(whoami)/}"
				if [[ -f "$expanded_reply" ]]; then
					echo
					echo "      ✅ You selected the key: $expanded_reply"
					export SSH_PRIVATE_KEY_HOST_PATH="$expanded_reply"
					export SSH_PUBLIC_KEY_HOST_PATH="$SSH_PRIVATE_KEY_HOST_PATH.pub"
					if [[ ! -f "$SSH_PUBLIC_KEY_HOST_PATH" ]]; then
						echo
						echo "      ❌ Warning: Corresponding .pub file not found."
					fi
					break
				else
					echo
					echo "      ❌ File not found! Please enter a valid file path or select a key from the list."
				fi
			else
				echo
				echo "      ❌ Invalid option. Try again."
			fi
	done
}

more_information() {
	echo "   For more information about the FUNTTASTIC CLIENT, please visit:"
	echo
	echo "      https://www.funttastic.com/partners/kujira"
}

info_back_or_exit() {
	echo "   ℹ️  Enter 'back' to return to previous menu or 'exit' to exit script."
}

show_title() {
	local title="$1"

	format_string() {
  	local input_str="$1"
  	local upper_str
  	local str_length
  	local total_length
  	local padding_length

  	upper_str=$(echo "$input_str" | tr '[:lower:]' '[:upper:]')
  	str_length=${#upper_str}
  	total_length=85
  	padding_length=$(( (total_length - str_length - 6) / 2 )) # 6 for the spaces (3 on each side)

  	if [ "$str_length" -gt 77 ]; then
  		# Adjust format for strings longer than 77 characters
  		echo "==  $upper_str  =="
  	else
  		local equal_signs
  		local remainder

  		equal_signs=$(printf '=%.0s' $(seq 1 $padding_length))
  		remainder=$(( (total_length - (2 * padding_length + str_length + 6)) ))

  		# Ensure total length is 85, adding an extra "=" at the end if necessary
  		if [ $remainder -gt 0 ]; then
  			echo "${equal_signs}   $upper_str   ${equal_signs}="
  		else
  			echo "${equal_signs}   $upper_str   ${equal_signs}"
  		fi
  	fi
  }

	clear
	echo
	echo "   $(format_string "$title")"
	echo
}

exit_application() {
	show_title "LEAVING THE SCRIPT"
	echo "      Feel free to come back whenever you want."
	echo
	more_information
	echo
	exit 0
}

waiting() {
	local sleep_time=${1:-$DEFAULT_WAITING_TIME}
	local spacer=$2

	for i in $(seq 1 "$sleep_time"); do
		echo -e "${spacer}Waiting $i-$sleep_time seconds to return."
		sleep 1
		tput cuu 1
		tput ed
	done
}

file_exists_in_container() {
  container=$1
  file=$2

  if docker exec "$container" [ -f "$file" ]; then
    return 0
  else
    return 1
  fi
}

pre_installation_password_encryption() {
	password_encryption_warning() {
		show_title "PASSWORD & USERNAME SETTING PROCESS"
		echo "   +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		echo "   |                                                               |"
		echo "   |  ⚠️  Attention! Answer the following question carefully!       |"
		echo "   |                                                               |"
		echo "   +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		echo
	}

	password_encryption_warning

  while true; do
  	echo "   Do you want to allow internal scripts to be able to decrypt"
  	echo "   your password automatically when you need to use it to "
  	echo "   restart an application?"
  	echo
  	echo "   ℹ️  If you choose 'No', you will need to enter your "
  	echo "      password whenever you need to restart an app."
  	echo
  	read -rp "   (\"Y/n\") >>> " RESPONSE

  	if [[ "$RESPONSE" == "Y" || "$RESPONSE" == "y" || \
  				"$RESPONSE" == "Yes" || "$RESPONSE" == "yes" || \
  				"$RESPONSE" == "" ||  \
  				"$RESPONSE" == "N" || "$RESPONSE" == "n" || \
  				"$RESPONSE" == "No" || "$RESPONSE" == "no" ]]; then
  		break
  	else
  		tput cuu 8
  		tput ed
  	fi
  done

  password_encryption_warning

  if [[ "$RESPONSE" == "Y" || "$RESPONSE" == "y" || "$RESPONSE" == "Yes" || "$RESPONSE" == "yes" || "$RESPONSE" == "" ]]; then
  	AUTO_SIGNIN="TRUE"

		# This 'return' is being used to disable the question below
		return

  	while true; do
  		echo "   ℹ️  To encrypt the password and username, we can use an SSH key "
  		echo "      pair that you already have."
  		echo
  		echo "   Do you want to use an existing SSH key pair?"
  		echo
  		echo "   Choose 'No' to create a new pair automatically."
  		echo
  		read -rp "   (\"y/N\") >>> " RESPONSE

    	if [[ "$RESPONSE" == "Y" || "$RESPONSE" == "y" || \
    				"$RESPONSE" == "Yes" || "$RESPONSE" == "yes" || \
    				"$RESPONSE" == "" ||  \
    				"$RESPONSE" == "N" || "$RESPONSE" == "n" || \
    				"$RESPONSE" == "No" || "$RESPONSE" == "no" ]]; then
    		break
    	else
    		tput cuu 7
    		tput ed
    	fi
    done

  	if [[ "$RESPONSE" == "Y" || "$RESPONSE" == "y" || "$RESPONSE" == "Yes" || "$RESPONSE" == "yes" ]]; then
  		password_encryption_warning
  		select_ssh_key
			echo
  		waiting 3 "   "
  	fi
  else
  	AUTO_SIGNIN="FALSE"
  fi
}

pre_installation_define_passphrase() {
	show_title "PASSWORD & USERNAME SETTING PROCESS"
	echo "   +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "   |                                                                 |"
	echo "   |  ⚠️  It's important that your data remains secure, so we need    |"
	echo "   |     to set a password and an username.                          |"
	echo "   |                                                                 |"
	echo "   |  See the table presented at the end of the password definition  |"
	echo "   |  process, where the password and username will be used.         |"
	echo "   |                                                                 |"
	echo "   +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo

	echo "   Let's get started!"

	echo
	read -rp "   Enter a username you want to use (default = \"admin\") >>> " RESPONSE

	if [ "$RESPONSE" == "" ]; then
		ADMIN_USERNAME="admin"
	else
		ADMIN_USERNAME="$RESPONSE"
	fi

	echo
	echo "      ℹ️  The username was defined to \"$ADMIN_USERNAME\""

	while true; do
		echo
		read -s -rp "   Enter a passphrase with at least $MIN_PASSPHRASE_LENGTH characters >>> " ADMIN_PASSWORD
		echo
		if [ -z "$ADMIN_PASSWORD" ] || [ ${#ADMIN_PASSWORD} -lt "$MIN_PASSPHRASE_LENGTH" ]; then
			echo
			echo "      ⚠️  Weak passphrase, please try again."
		else
			while true; do
				echo
				echo "   Please, repeat the passphrase. ℹ️  Enter \"see-pass\" to momentarily see the previously entered password."
				echo
				read -s -rp "   >>> " REPEATED_PASSPHRASE

				if [ "$REPEATED_PASSPHRASE" = "see-pass" ]; then
					echo "$ADMIN_PASSWORD"
					sleep 3
					tput cuu 4
					tput ed
				elif [ "$REPEATED_PASSPHRASE" = "$ADMIN_PASSWORD" ]; then
					tput cuu 1
					echo
					echo -e "\r      ✅ Perfect, the passphrase has been set successfully.$(printf ' %.0s' {1..20})"
					break
				else
					tput cuu 1
					echo
					echo -e "\r      ❌ Passphrases do not match, please try again.$(printf ' %.0s' {1..20})"
				fi
			done
			break
		fi
	done

	pre_installation_password_encryption

	show_title "PASSWORD & USERNAME SETTING PROCESS"
	echo "   ________________________________________________________________"
	echo "   | SERVICE OR APPLICATION |  NEEDS USERNAME  |  NEEDS PASSWORD  |"
	echo "   |¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|"
	echo "   |  Funttastic UI         |       Yes        |        Yes       |"
	echo "   |  FileBrowser           |       Yes        |        Yes       |"
	echo "   |  Hummingbot Client     |        No        |        Yes       |"
	echo "   |  Hummingbot Gateway    |        No        |        Yes       |"
	echo "   |  SSL Certificates      |        No        |        Yes       |"
	echo "   |______________________________________________________________|"

	echo
	read -s -n1 -rp "   Alright, I got it! Press any key to continue >>> "
}

pre_installation_fun_frontend() {
	show_title "FUNTTASTIC FRONTEND INSTALLATION SETTINGS"

	default_values_info

	echo
	read -rp "   Enter a port to expose the Funttastic Frontend from the instance (default = \"50000\") >>> " RESPONSE

	if [ "$RESPONSE" == "" ]; then
		FUN_FRONTEND_PORT=50000
	else
		FUN_FRONTEND_PORT=$RESPONSE
	fi

	FUN_FRONTEND_URL="http://localhost:$FUN_FRONTEND_PORT"
	FUN_FRONTEND_REPOSITORY_URL="https://github.com/funttastic/fun-hb-frontend.git"
	FUN_FRONTEND_REPOSITORY_BRANCH="development"
}

pre_installation_filebrowser() {
	show_title "FILEBROWSER INSTALLATION SETTINGS"

	default_values_info

	echo
	read -rp "   Enter a port to expose the FileBrowser from the instance (default = \"50002\") >>> " RESPONSE

	if [ "$RESPONSE" == "" ]; then
		FILEBROWSER_PORT=50002
	else
		FILEBROWSER_PORT=$RESPONSE
	fi

	FILEBROWSER_URL="http://localhost:$FILEBROWSER_PORT"
}

pre_installation_image_and_container() {
	show_title "DOCKER IMAGE AND CONTAINER SETTINGS"

	default_values_info

	should_prune_docker() {
		echo
		read -rp "   Are you sure you want to remove all Docker images and containers? (\"y/N\") >>> " RESPONSE

		if [[ "$RESPONSE" == "Y" || "$RESPONSE" == "y" || "$RESPONSE" == "Yes" || "$RESPONSE" == "yes" ]]; then
			return 0
		else
			return 1
		fi
	}

	customize_image_name() {
		# Customize the new image name?
		echo
		read -rp "   Enter a name for your new installation image (default = \"fun-kuji-hb\") >>> " RESPONSE

		echo

		if [ -z "$RESPONSE" ]; then
			IMAGE_NAME="fun-kuji-hb"
		else
			IMAGE_NAME="$RESPONSE"
		fi
	}

	should_reuse_image() {
		echo
		read -rp "   Do you want to use an image from a previous installation? (\"y/N\") >>> " RESPONSE

		if [[ "$RESPONSE" == "N" || "$RESPONSE" == "n" || "$RESPONSE" == "" ]]; then
			return 1
		else
			return 0
		fi
	}

	if should_reuse_image; then
		while true; do
			echo
      read -rp "   Which image do you want to reuse? (default = \"fun-kuji-hb\") >>> " RESPONSE

      if [ "$RESPONSE" == "" ]; then
      	IMAGE_NAME="fun-kuji-hb"
      else
      	IMAGE_NAME="$RESPONSE"
      fi

      if image_exists "$IMAGE_NAME"; then
      	echo
      	echo "      The image {$IMAGE_NAME} will be reused."
      	echo "      A new image will not be created, just a new container."
      	break
      else
      	echo "   ⚠️  Image not found! Please enter a valid image name."
      fi
		done
	else
		echo
		echo "      A new image/installation will be done..."

		BUILD_CACHE="--no-cache"

		handle_image_name_conflict() {
			echo "   ⚠️  An installation image with the name \"$IMAGE_NAME\" already exists!"
			echo
			echo "      To ensure that no crashes occur while creating this new image, choose one"
			echo "      of the options below."
			echo
			echo "      [1] SET A DIFFERENT NAME"
			echo "      [2] REMOVE EXISTING IMAGE"
			echo "      [3] REMOVE ALL IMAGES & CONTAINERS"
			echo

			read -rp "      Enter your choice (1, 2 or 3): " OPTION

			case $OPTION in
			1)
				while true; do
					customize_image_name

					if image_exists "$IMAGE_NAME"; then
						echo "      ⚠️  The name \"$IMAGE_NAME\" is already in use. Please choose a different name."
					else
						echo "      ✅ The name {$IMAGE_NAME} has been defined for your new image."
						break
					fi
				done
				;;
			2)
				echo
				read -rp "   Are you sure you want to remove the image \"$IMAGE_NAME\"? (\"y/N\") >>> " RESPONSE

				if [[ "$RESPONSE" == "Y" || "$RESPONSE" == "y" || "$RESPONSE" == "Yes" || "$RESPONSE" == "yes" ]]; then
					docker_prune_selectively "$IMAGE_NAME"
				else
					tput cuu 12
          tput ed

          handle_image_name_conflict
				fi
				;;
			3)
				if should_prune_docker; then
					./scripts/utils/destroy-all-containers-and-images.sh >/dev/null 2>&1 &
				else
					tput cuu 12
					tput ed

					handle_image_name_conflict
				fi
				;;
			*)
				tput cuu 10
        tput ed

				handle_image_name_conflict
				;;
			esac
		}

		customize_image_name

		if image_exists "$IMAGE_NAME"; then
			handle_image_name_conflict
		else
			echo "      ✅ The name {$IMAGE_NAME} has been defined for your new image."
		fi
	fi

	customize_container_name() {
		# Create a new container?
		RESPONSE="$CONTAINER_NAME"
		echo
		read -rp "   Enter a name for your new instance/container (default = \"fun-kuji-hb\") >>> " RESPONSE

		if [ "$RESPONSE" == "" ]; then
			CONTAINER_NAME="fun-kuji-hb"
		else
			CONTAINER_NAME=$RESPONSE
		fi
	}

	handle_container_name_conflict() {
		echo
		echo "      ⚠️  An container with the name \"$CONTAINER_NAME\", which you defined, already exists!"
		echo
		echo "      To ensure that no crashes occur while creating this new container, choose one"
		echo "      of the options below."
		echo
		echo "      [1] SET A DIFFERENT NAME"
		echo "      [2] REMOVE EXISTING CONTAINER"
		echo "      [3] REMOVE ALL IMAGES & CONTAINERS [USE WITH CARE]"
		echo

		read -rp "      Enter your choice (1, 2 or 3): " OPTION

		case $OPTION in
		1)
			while true; do
				customize_container_name
				if container_exists "$CONTAINER_NAME"; then
					echo
					echo "      ⚠️  The name \"$CONTAINER_NAME\" is already in use. Please choose a different name."
				else
					echo
					echo "      ✅ The name \"$CONTAINER_NAME\" is set for your new instance/container."

					break
				fi
			done
			;;
		2)
			echo
			read -rp "   Are you sure you want to remove the container \"$CONTAINER_NAME\"? (\"y/N\") >>> " RESPONSE

			if [[ "$RESPONSE" == "Y" || "$RESPONSE" == "y" || "$RESPONSE" == "Yes" || "$RESPONSE" == "yes" ]]; then
      	remove_docker_container "$CONTAINER_NAME"
      else
      	tput cuu 13
        tput ed

        handle_container_name_conflict
      fi
			;;
		3)
			if should_prune_docker; then
				./scripts/utils/destroy-all-containers-and-images.sh >/dev/null 2>&1 &
			else
				tput cuu 13
				tput ed

				handle_container_name_conflict
			fi
			;;
		*)
			tput cuu 11
			tput ed

			handle_container_name_conflict
			;;
		esac
	}

	customize_container_name

	if container_exists "$CONTAINER_NAME"; then
		handle_container_name_conflict
	fi
}

pre_installation_fun_client() {
	if [ "$BUILD_CACHE" == "" ]; then
  	return
  fi

	show_title "FUNTTASTIC CLIENT INSTALLATION SETTINGS"

	default_values_info

	# Expose which port?
	echo
	read -rp "   Enter a port to expose the Funttastic Client from the instance (default = \"50001\") >>> " RESPONSE

	if [ "$RESPONSE" == "" ]; then
		FUN_CLIENT_PORT=50001
	else
		FUN_CLIENT_PORT=$RESPONSE
	fi

	echo
	echo "   Enter the url from the repository to be cloned"
	read -rp "   (default = \"https://github.com/funttastic/fun-hb-client.git\") >>> " RESPONSE

	if [ "$RESPONSE" == "" ]; then
		FUN_CLIENT_REPOSITORY_URL="https://github.com/funttastic/fun-hb-client.git"
	else
		FUN_CLIENT_REPOSITORY_URL="$RESPONSE"
	fi

	echo
	read -rp "   Enter the branch from the repository to be cloned (default = \"community\") >>> " RESPONSE

	if [ "$RESPONSE" == "" ]; then
		FUN_CLIENT_REPOSITORY_BRANCH="community"
	else
		FUN_CLIENT_REPOSITORY_BRANCH="$RESPONSE"
	fi
}

pre_installation_hb_client() {
	show_title "HUMMINGBOT CLIENT INSTALLATION SETTINGS"

	default_values_info

	if [ "$BUILD_CACHE" == "--no-cache" ]; then
		echo
		echo "   Enter the url from the repository to be cloned"
		read -rp "   (default = \"https://github.com/Team-Kujira/hummingbot.git\") >>> " RESPONSE

		if [ "$RESPONSE" == "" ]; then
			HB_CLIENT_REPOSITORY_URL="https://github.com/Team-Kujira/hummingbot.git"
		else
			HB_CLIENT_REPOSITORY_URL="$RESPONSE"
		fi

		echo
		read -rp "   Enter the branch from the repository to be cloned (default = \"community\") >>> " RESPONSE

		if [ "$RESPONSE" == "" ]; then
			HB_CLIENT_REPOSITORY_BRANCH="community"
		else
			HB_CLIENT_REPOSITORY_BRANCH="$RESPONSE"
		fi
	fi
}

pre_installation_hb_gateway() {
	if [ "$BUILD_CACHE" == "" ]; then
  	return
  fi

	show_title "HUMMINGBOT GATEWAY INSTALLATION SETTINGS"

	default_values_info

	# Exposed port?
	echo
	echo "   Do you want to expose the Gateway port from the instance?"
	echo
	echo "   The recommended option is \"No\", but if you choose \"No\""
	echo "   you will not be able to make calls directly to the Gateway."
	echo
	read -rp "   (\"y/N\") >>> " RESPONSE

	if [[ "$RESPONSE" == "N" || "$RESPONSE" == "n" || "$RESPONSE" == "No" || "$RESPONSE" == "no" || "$RESPONSE" == "" ]]; then
		echo
		echo "   ℹ️  The Gateway port will not be exposed from the instance, only Funttastic Client and"
		echo "       Hummingbot Client will be able to make calls to it from within the container."

		EXPOSE_HB_GATEWAY_PORT="FALSE"
	else
		EXPOSE_HB_GATEWAY_PORT="TRUE"

		echo
		read -rp "   Enter a port to expose the Hummingbot Gateway from the instance (default = \"15888\") >>> " RESPONSE

		if [ "$RESPONSE" == "" ]; then
			HB_GATEWAY_PORT=15888
		else
			HB_GATEWAY_PORT=$RESPONSE
		fi
	fi

	echo
	echo "   Enter the url from the repository to be cloned"
	read -rp "   (default = \"https://github.com/Team-Kujira/gateway.git\") >>> " RESPONSE

	if [ "$RESPONSE" == "" ]; then
		HB_GATEWAY_REPOSITORY_URL="https://github.com/Team-Kujira/gateway.git"
	else
		HB_GATEWAY_REPOSITORY_URL="$RESPONSE"
	fi

	echo
	read -rp "   Enter the branch from the repository to be cloned (default = \"community\") >>> " RESPONSE

	if [ "$RESPONSE" == "" ]; then
		HB_GATEWAY_REPOSITORY_BRANCH="community"
	else
		HB_GATEWAY_REPOSITORY_BRANCH="$RESPONSE"
	fi
}

pre_installation_launch_apps_after_installation() {
	show_title "HUMMINGBOT CLIENT INITIALIZATION SETTING"

	default_values_info

	echo
	read -rp "   Do you want to open the Hummingbot Client UI automatically after installation? (\"Y/n\") >>> " RESPONSE

	if [[ "$RESPONSE" == "Y" || "$RESPONSE" == "y" || "$RESPONSE" == "Yes" || "$RESPONSE" == "yes" || "$RESPONSE" == "" ]]; then
		echo
		echo "      The app will start automatically after installation."
		HB_CLIENT_ATTACH="TRUE"
	else
		HB_CLIENT_ATTACH="FALSE"
	fi
}

pre_installation_change_post_installation_commands() {
	if [ "$BUILD_CACHE" == "" ]; then
  	return
  fi

	show_title "CUSTOMIZING POST-INSTALLATION COMMANDS"

	default_values_info

	echo
	read -rp "   Do you want to customize any app launch commands? (\"y/N\") >>> " RESPONSE

	if [[ "$RESPONSE" == "Y" || "$RESPONSE" == "y" || "$RESPONSE" == "Yes" || "$RESPONSE" == "yes" ]]; then
		show_title "CUSTOMIZING POST-INSTALLATION COMMANDS"
		echo "   CHOOSE WHICH SERVICE WHOSE COMMAND YOU WOULD LIKE TO CHANGE:"
		echo
		echo "   [1] CHANGE ALL APPS COMMANDS"
		echo "   [2] FUNTTASTIC CLIENT SERVER COMMAND"
		echo "   [3] FUNTTASTIC CLIENT FRONTEND COMMAND"
		echo "   [4] HUMMINGBOT CLIENT COMMAND"
		echo "   [5] HUMMINGBOT GATEWAY COMMAND"
		echo "   [6] FILEBROWSER COMMAND"
		echo

		read -rp "   Enter your choice (1, 2, 3, 4, 5 or 6): " APP_COMMAND

		tput cuu 10
		tput ed

		set_app_post_installation_command() {
			local default_command="$1"
			local app_name="$2"
			local target_app_command_var_name="$3" # This is the name of the variable we want to set
			local sleep_time="${4:-0}"

			# First, we check if the target variable already has a value (using variable indirection)
			local RESPONSE="${!target_app_command_var_name}"
			if [ -z "$RESPONSE" ]; then
				echo
				echo "   ℹ️  Let's change $app_name command."
				echo
				echo "   The $app_name default command is:"
				echo
				echo "      $default_command"
				echo
				echo "   Enter the new command for the $app_name (or press ENTER to maintain default):"
				echo
				read -rp "   >>> " RESPONSE
			fi

			if [ -n "$RESPONSE" ]; then
				# Here we use eval to assign the value of RESPONSE to the variable named by target_app_command_var_name
				eval "${target_app_command_var_name}='${RESPONSE}'"
				echo
				echo "      The new command for $app_name was defined as:"
				# To display the value, we need variable indirection again
				echo "         ${!target_app_command_var_name}"
				sleep "$sleep_time"
			fi
		}

		local default_fun_client_server_command="conda activate funttastic && cd /root/funttastic/client && python app.py > /dev/null 2>&1 &"
		local default_fun_client_frontend_command="cd /root/funttastic/frontend && yarn start --host > /dev/null 2>&1 &"
		local default_hummingbot_client_command="conda activate hummingbot && cd /root/hummingbot/client && python bin/hummingbot_quickstart.py 2>> ./logs/errors.log"
		local default_hummingbot_gateway_command="cd /root/hummingbot/gateway && yarn start > /dev/null 2>&1 &"
		local default_filebrowser_command="cd /root/filebrowser && filebrowser --address=0.0.0.0 -p \$FILEBROWSER_PORT -r ../shared > /dev/null 2>&1 &"

		while true; do
			case $APP_COMMAND in
			1)
				show_title "CUSTOMIZING POST-INSTALLATION COMMANDS"
				set_app_post_installation_command "$default_fun_client_server_command" "Funttastic Client Server" "FUN_CLIENT_COMMAND"

				show_title "CUSTOMIZING POST-INSTALLATION COMMANDS"
				set_app_post_installation_command "$default_fun_client_frontend_command" "Funttastic Client Frontend" "FUN_FRONTEND_COMMAND"

				show_title "CUSTOMIZING POST-INSTALLATION COMMANDS"
				set_app_post_installation_command "$default_hummingbot_client_command" "Hummingbot Client" "HB_CLIENT_COMMAND"

				show_title "CUSTOMIZING POST-INSTALLATION COMMANDS"
				set_app_post_installation_command "$default_hummingbot_gateway_command" "Hummingbot Gateway" "HB_GATEWAY_COMMAND"

				show_title "CUSTOMIZING POST-INSTALLATION COMMANDS"
				set_app_post_installation_command "$default_filebrowser_command" "FileBrowser" "FILEBROWSER_COMMAND"

				show_title "CUSTOMIZING POST-INSTALLATION COMMANDS"
				echo "   See below the modified commands:"
				echo

				if [ -n "$FUN_CLIENT_COMMAND" ]; then
					echo "      Funttastic Client Server: $FUN_CLIENT_COMMAND"
					echo
				fi
				if [ -n "$FUN_FRONTEND_COMMAND" ]; then
					echo "      Funttastic Client Frontend: $FUN_FRONTEND_COMMAND"
					echo
				fi
				if [ -n "$HB_GATEWAY_COMMAND" ]; then
					echo "      Hummingbot Gateway Command: $HB_GATEWAY_COMMAND"
					echo
				fi
				if [ -n "$HB_CLIENT_COMMAND" ]; then
					echo "      Hummingbot Client Command: $HB_CLIENT_COMMAND"
					echo
				fi
				if [ -n "$FILEBROWSER_COMMAND" ]; then
					echo "      FileBrowser Command: $FILEBROWSER_COMMAND"
					echo
				fi

				break
				;;
			2)
				show_title "CUSTOMIZING POST-INSTALLATION COMMANDS"
				set_app_post_installation_command "$default_fun_client_server_command" "Funttastic Client Server" "FUN_CLIENT_COMMAND" 3
				break
				;;
			3)
				show_title "CUSTOMIZING POST-INSTALLATION COMMANDS"
				set_app_post_installation_command "$default_fun_client_frontend_command" "Funttastic Client Frontend" "FUN_FRONTEND_COMMAND" 3
				break
				;;
			4)
				show_title "CUSTOMIZING POST-INSTALLATION COMMANDS"
				set_app_post_installation_command "$default_hummingbot_client_command" "Hummingbot Client" "HB_CLIENT_COMMAND" 3
				break
				;;
			5)
				show_title "CUSTOMIZING POST-INSTALLATION COMMANDS"
				set_app_post_installation_command "$default_hummingbot_gateway_command" "Hummingbot Gateway" "HB_GATEWAY_COMMAND" 3
				break
				;;
			6)
				show_title "CUSTOMIZING POST-INSTALLATION COMMANDS"
				set_app_post_installation_command "$default_filebrowser_command" "FileBrowser" "FILEBROWSER_COMMAND" 3
				break
				;;
			*)
				echo
				echo "      ❌ Invalid Input. Enter a your choice (1, 2, 3, 4, 5 or 6)."
				echo
				read -rp "   Enter your choice (1, 2, 3, 4, 5 or 6): " APP_COMMAND
				;;
			esac
		done
	fi
}

pre_installation_open_apps_in_browser() {
	show_title "OPEN APPS IN THE BROWSER"

	default_values_info

	echo
	echo "   Do you want to open the management app in the browser after the installation is complete?"
	echo
	echo "   It will open:"
	echo
	echo "      > FUNTTASTIC CLIENT FRONTEND [$FUN_FRONTEND_URL]"
	echo
	read -rp "   [\"Y/n\"] >>> " RESPONSE

	if [[ "$RESPONSE" == "Y" || "$RESPONSE" == "y" || "$RESPONSE" == "Yes" || "$RESPONSE" == "yes" || "$RESPONSE" == "" ]]; then
		OPEN_IN_BROWSER="TRUE"
	else
		OPEN_IN_BROWSER="FALSE"
	fi
}

pre_installation_lock_apt() {
	if [ "$BUILD_CACHE" == "" ]; then
		return
	fi

	show_title "LOCK ADDING NEW PACKAGES"

	default_values_info

	echo
	echo "   Do you want to eliminate the possibility of installing new packages inside the"
	read -rp "   container after its creation? (\"Y/n\") >>> " RESPONSE

	if [[ "$RESPONSE" == "Y" || "$RESPONSE" == "y" || "$RESPONSE" == "Yes" || "$RESPONSE" == "yes" || "$RESPONSE" == "" ]]; then
		echo
		echo "   ℹ️  You have chosen to block the addition of new packages."
		LOCK_APT="TRUE"
	else
		echo
		echo "      The installation of new packages will be allowed."
		LOCK_APT="FALSE"
	fi
}

install_menu() {
	pre_installation_define_passphrase

  show_title "INSTALLATION OPTIONS"

  echo "   Do you want to automate the entire process? [Y/n]"

  echo
  echo "   ℹ️  Enter the value [back] to return to the main menu."
  echo

  read -rp "   [Y/n/back] >>> " RESPONSE
  if [[ "$RESPONSE" == "Y" || "$RESPONSE" == "y" || "$RESPONSE" == "" ]]; then
  	echo
  elif [[ "$RESPONSE" == "back" ]]; then
  	clear
  	main_menu
  	exit_application
  else
  	CUSTOMIZE="--customize"
  fi

  if [ "$CUSTOMIZE" == "--customize" ]; then
  	CHOICE="ALL"
  	pre_installation_image_and_container
  	pre_installation_fun_client
  	pre_installation_fun_frontend
  	pre_installation_hb_gateway
  	pre_installation_filebrowser
  	pre_installation_hb_client
  	pre_installation_launch_apps_after_installation
  	pre_installation_change_post_installation_commands
  	pre_installation_open_apps_in_browser
  	pre_installation_lock_apt
  else
  	# Default settings to install Funttastic Client, Hummingbot Gateway and Hummingbot Client

  	LOCAL_HOST_URL_PREFIX="http://localhost"

  	# Funttastic Frontend Settings
  	FUN_FRONTEND_PORT=${FUN_FRONTEND_PORT:-50000}
  	FUN_FRONTEND_URL="$LOCAL_HOST_URL_PREFIX:$FUN_FRONTEND_PORT"
  	FUN_FRONTEND_REPOSITORY_URL=${FUN_FRONTEND_REPOSITORY_URL:-"https://github.com/funttastic/fun-hb-frontend.git"}
  	FUN_FRONTEND_REPOSITORY_BRANCH=${FUN_FRONTEND_REPOSITORY_BRANCH:-"development"}

  	# Filebrowser Settings
  	FILEBROWSER_PORT=${FILEBROWSER_PORT:-50002}
  	FILEBROWSER_URL="$LOCAL_HOST_URL_PREFIX:$FILEBROWSER_PORT"

  	# Funttastic Client Settings
  	FUN_CLIENT_PORT=${FUN_CLIENT_PORT:-50001}
  	FUN_CLIENT_REPOSITORY_URL=${FUN_CLIENT_REPOSITORY_URL:-"https://github.com/funttastic/fun-hb-client.git"}
  	FUN_CLIENT_REPOSITORY_BRANCH=${FUN_CLIENT_REPOSITORY_BRANCH:-"development"}
  	FUN_CLIENT_AUTO_START=${FUN_CLIENT_AUTO_START:-"TRUE"}

  	# Hummingbot Client Settings
  	HB_CLIENT_REPOSITORY_URL=${HB_CLIENT_REPOSITORY_URL:-"https://github.com/Team-Kujira/hummingbot.git"}
  	HB_CLIENT_REPOSITORY_BRANCH=${HB_CLIENT_REPOSITORY_BRANCH:-"development"}
  	HB_CLIENT_ATTACH=${HB_CLIENT_ATTACH:-"TRUE"}

  	# Hummingbot Gateway Settings
  	HB_GATEWAY_PORT=${HB_GATEWAY_PORT:-15888}
  	HB_GATEWAY_REPOSITORY_URL=${HB_GATEWAY_REPOSITORY_URL:-"https://github.com/Team-Kujira/gateway.git"}
  	HB_GATEWAY_REPOSITORY_BRANCH=${HB_GATEWAY_REPOSITORY_BRANCH:-"development"}
  	HB_GATEWAY_AUTO_START=${HB_GATEWAY_AUTO_START:-"TRUE"}
  	HB_GATEWAY_AUTO_START_EVERY_TIME=${HB_GATEWAY_AUTO_START_EVERY_TIME:-"TRUE"}
  	EXPOSE_HB_GATEWAY_PORT=${EXPOSE_HB_GATEWAY_PORT:-"FALSE"}

  	# Common Settings
  	ADMIN_USERNAME=${ADMIN_USERNAME:-"admin"}
  	IMAGE_NAME="fun-kuji-hb"
  	CONTAINER_NAME="$IMAGE_NAME"
  	BUILD_CACHE=${BUILD_CACHE:-"--no-cache"}
  	TAG=${TAG:-"latest"}
  	ENTRYPOINT=${ENTRYPOINT:-""}
  	#  ENTRYPOINT=${ENTRYPOINT:-"--entrypoint=\"source /root/.bashrc && start\""}
  	OPEN_IN_BROWSER=${OPEN_IN_BROWSER:-"TRUE"}
  	LOCK_APT=${LOCK_APT:-"TRUE"}

  	if image_exists "$IMAGE_NAME"; then
  		docker_prune_selectively "$IMAGE_NAME"
  	fi

  	# If there is a conflicting container of a non-conflicting image
  	if container_exists "$CONTAINER_NAME"; then
  		remove_docker_container "$CONTAINER_NAME"
  	fi
  fi

  if [ -z "$CUSTOMIZE" ]; then
  	echo "   |¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|"
  	echo "   |                                       ** TIPS **                                       |"
  	echo "   |________________________________________________________________________________________|"
  	echo "   |                                     |                                                  |"
  	echo "   |   ℹ️   After the installation,      |   ℹ️   Quitting Hummingbot Client                |"
  	echo "   |                                     |                                                  |"
  	echo "   |   to view and edit configuration    |   If you need to close the 'Hummingbot Client'   |"
  	echo "   |   files, use the Frontend at        |   interface without shutting down the entire     |"
  	echo "   |                                     |   container, close the terminal window or tab    |"
  	echo "   |      https://localhost:50000        |   or use the command below:                      |"
  	echo "   |                                     |                                                  |"
  	echo "   |                                     |            [Ctrl+p] and then [Ctrl+q]            |"
  	echo "   |_____________________________________|__________________________________________________|"
  	echo
  fi

	if [[ "$CUSTOMIZE" == "--customize" && ! "$NOT_IMPLEMENTED" ]]; then
  	clear

  	if [ "$BUILD_CACHE" == "--no-cache" ]; then
  		REUSE_IMAGE="FALSE"
  	else
  		REUSE_IMAGE="TRUE"
  	fi

  	if [ -z "$ENTRYPOINT" ]; then
  		DEFINED_ENTRYPOINT="Default"
  	else
  		DEFINED_ENTRYPOINT="$ENTRYPOINT"
  	fi

  	show_title "SETTINGS CONFIRMATION"

  	echo
  	echo "   ℹ️  Confirm below if the common settings are correct:"
  	echo
  	printf "%25s %5s\n" "Image:" "$IMAGE_NAME"
  	printf "%25s %5s\n" "Instance:" "$CONTAINER_NAME"
  	printf "%25s %3s\n" "Reuse image:" "$REUSE_IMAGE"
  	printf "%25s %5s\n" "Version:" "$TAG"
  	printf "%25s %5s\n" "Entrypoint:" "$DEFINED_ENTRYPOINT"
  	if [ "$BUILD_CACHE" == "--no-cache" ]; then
  		printf "%25s %3s\n" "Lock APT:" "$LOCK_APT"
  	fi
  	printf "%25s %3s\n" "Open Management App:" "$OPEN_IN_BROWSER"
  	echo

  	if [ "$BUILD_CACHE" == "--no-cache" ]; then
  		echo
      echo "   ℹ️  Confirm below if the Funttastic Client Server settings are correct:"
      echo
  		printf "%25s %5s\n" "Repository url:" "$FUN_CLIENT_REPOSITORY_URL"
  		printf "%25s %5s\n" "Repository branch:" "$FUN_CLIENT_REPOSITORY_BRANCH"
  		printf "%25s %4s\n" "Exposed port:" "$FUN_CLIENT_PORT"
      echo
  	fi

  	echo
  	echo "   ℹ️  Confirm below if the Funttastic Client Fronted settings are correct:"
  	echo
  	if [ "$BUILD_CACHE" == "--no-cache" ]; then
  		printf "%25s %5s\n" "Repository url:" "$FUN_FRONTEND_REPOSITORY_URL"
  		printf "%25s %5s\n" "Repository branch:" "$FUN_FRONTEND_REPOSITORY_BRANCH"
  	fi
  	printf "%25s %4s\n" "Exposed port:" "$FUN_FRONTEND_PORT"
  	printf "%25s %4s\n" "Access URL:" "$FUN_FRONTEND_URL"
  	echo

  	echo
  	echo "   ℹ️  Confirm below if the Hummingbot Client settings are correct:"
  	echo
  	if [ "$BUILD_CACHE" == "--no-cache" ]; then
  		printf "%25s %5s\n" "Repository url:" "$HB_CLIENT_REPOSITORY_URL"
  		printf "%25s %5s\n" "Repository branch:" "$HB_CLIENT_REPOSITORY_BRANCH"
  	fi
  	printf "%25s %3s\n" "See UI On Finish:" "$HB_CLIENT_ATTACH"

		if [[ "$BUILD_CACHE" == "--no-cache" || "$EXPOSE_HB_GATEWAY_PORT" == "TRUE" ]]; then
			echo
			echo "   ℹ️  Confirm below if the Hummingbot Gateway settings are correct:"
			echo
  	fi
  	if [ "$BUILD_CACHE" == "--no-cache" ]; then
  		printf "%25s %5s\n" "Repository url:" "$HB_GATEWAY_REPOSITORY_URL"
  		printf "%25s %5s\n" "Repository branch:" "$HB_GATEWAY_REPOSITORY_BRANCH"
  	fi
  	if [ "$EXPOSE_HB_GATEWAY_PORT" == "TRUE" ]; then
  		printf "%25s %4s\n" "Exposed port:" "$HB_GATEWAY_PORT"
  	fi
  	echo

  	echo
  	echo "   ℹ️  Confirm below if the FileBrowser settings are correct:"
  	echo
  	printf "%25s %4s\n" "Exposed port:" "$FILEBROWSER_PORT"
  	printf "%25s %4s\n" "Access URL:" "$FILEBROWSER_URL"
  	echo

		if [ "$BUILD_CACHE" == "--no-cache" ]; then
			if [[ -n "$FUN_CLIENT_COMMAND" || -n "$FUN_FRONTEND_COMMAND" || -n "$HB_GATEWAY_COMMAND" || -n "$HB_CLIENT_COMMAND" || -n "$FILEBROWSER_COMMAND" ]]; then
				echo
				echo "   ℹ️  Confirm below if the personalized apps post installation commands are correct:"
				echo

				if [ -n "$FUN_CLIENT_COMMAND" ]; then
					printf "%42s %s\n" "Funttastic Client Server Command:" "$FUN_CLIENT_COMMAND"
				fi
				if [ -n "$FUN_FRONTEND_COMMAND" ]; then
					printf "%42s %s\n" "Funttastic Client Frontend Command:" "$FUN_FRONTEND_COMMAND"
				fi
				if [ -n "$HB_GATEWAY_COMMAND" ]; then
					printf "%42s %s\n" "Hummingbot Gateway Command:" "$HB_GATEWAY_COMMAND"
				fi
				if [ -n "$HB_CLIENT_COMMAND" ]; then
					printf "%42s %s\n" "Hummingbot Client Command:" "$HB_CLIENT_COMMAND"
				fi
				if [ -n "$FILEBROWSER_COMMAND" ]; then
					printf "%42s %s\n" "FileBrowser Command:" "$FILEBROWSER_COMMAND"
				fi

				echo
				echo
			fi
  	fi

  	prompt_proceed

  	if [[ "$PROCEED" == "Y" || "$PROCEED" == "y" ]]; then
  		echo
  		install_docker
  	else
  		echo
  		echo "   Installation aborted!"
  		echo
  	fi
  else
  	if [ ! "$NOT_IMPLEMENTED" ]; then
  		CHOICE="ALL"
  		install_docker
  	fi
  fi
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

get_container_name() {
	if [ -n "$CONTAINER_NAME" ]; then
		return 0
	fi

	filter_containers

	show_title "CONTAINER SELECTION"
	info_back_or_exit
	echo

	while true; do
		if [ -n "$CONTAINER_NAME" ]; then
			echo "   Enter the container name (was found: \"$CONTAINER_NAME\")"

			echo
			echo "   [Press Enter to use '$CONTAINER_NAME']"
			echo
		else
			echo "   Enter the container name (example: \"fun-kuji-hb\"):"
			echo
		fi

		read -rp "   >>> " input_name

		if [ "$input_name" == "exit" ]; then
			exit_application
		elif [ "$input_name" == "back" ]; then
			main_menu
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
						echo "   ⚠️  Container not found! Please enter a valid container."
						echo
					fi
				fi

				read -rp "   >>> " input_name

				if [ "$input_name" == "exit" ]; then
					exit_application
				elif [ "$input_name" == "back" ]; then
					main_menu
				fi
			done
		elif [ -z "$CONTAINER_NAME" ]; then
			while true; do
				if [ -z "$input_name" ]; then
					echo
					echo "   ⚠️  Please enter a container name."
					echo
				else
					if container_exists "$input_name"; then
						CONTAINER_NAME="$input_name"
						return 0
					else
						echo
						echo "   ⚠️  Container not found! Please enter a valid container name."
						echo
					fi
				fi

				read -rp "   >>> " input_name

				if [ "$input_name" == "exit" ]; then
					exit_application
				elif [ "$input_name" == "back" ]; then
					main_menu
				fi
			done
		fi
	done
}

container_is_running() {
    # Accepts a container name or id as the first argument
    local container_name_or_id="$1"

#		# Checks if the specified container is running using docker ps
#		if [ -n "$(docker ps -q -f name="$container_name_or_id")" ]; then
#				return 0
#		else
#				return 1
#		fi

    # Checks if the specified container is running using docker inspect
		if [ "$(docker inspect -f '{{.State.Running}}' "$container_name_or_id")" == "true" ]; then
        return 0
    else
        return 1
    fi
}


set_urls() {
	if container_is_running "$CONTAINER_NAME"; then
		local FILEBROWSER_PORT
		local FUN_FRONTEND_PORT
		local LOCAL_HOST_URL_PREFIX="http://localhost"
		declare -g FILEBROWSER_URL
		declare -g FUN_FRONTEND_URL

		FILEBROWSER_PORT=$(docker exec "$CONTAINER_NAME" /bin/bash -c "grep 'FILEBROWSER_PORT=' /root/.bashrc | cut -d'=' -f2")
		FUN_FRONTEND_PORT=$(docker exec "$CONTAINER_NAME" /bin/bash -c "grep 'FRONTEND_PORT=' /root/.bashrc | cut -d'=' -f2")
		FILEBROWSER_URL="$LOCAL_HOST_URL_PREFIX:$FILEBROWSER_PORT"
		FUN_FRONTEND_URL="$LOCAL_HOST_URL_PREFIX:$FUN_FRONTEND_PORT"
	fi
}

restart_container() {
	local container_name=${1:-$CONTAINER_NAME}

	if [ "$container_name" == "back" ]; then
		return 0
	fi

	echo
	echo "      Stopping: $({
		docker stop -t 1 "$container_name" && sleep 1 &&
			if container_is_running "$container_name"; then
				docker kill "$container_name"
			fi
	} 2>&1)"

	echo
	echo "      Starting: $(docker start "$container_name" 2>&1)"

	if container_is_running "$container_name"; then
		if ! file_exists_in_container "$container_name" "/root/.ssh/id_rsa"; then
			while true; do
      	echo
      	echo "   Automatic login is disabled, you will need to enter the username"
      	echo "   and password defined during installation to start the services:"
      	echo
      	read -rp "   Username: " ADMIN_USERNAME
      	read -rsp "   Password: " ADMIN_PASSWORD
      	echo

      	if [[ -n "$ADMIN_USERNAME" && -n "$ADMIN_PASSWORD" ]]; then
      		break
      	fi
      done

			start_all_services

      if [ $? -eq 0 ]; then
				return 0
      else
				return 1
      fi
		fi
	fi
}

start_all_services() {
	docker exec -it -e ADMIN_USERNAME="$ADMIN_USERNAME" -e ADMIN_PASSWORD="$ADMIN_PASSWORD" "$CONTAINER_NAME" bash -c "source /root/.bashrc && start"
}

restart_all_services() {
	restart_container "$CONTAINER_NAME"
}

fun_client_send_request() {
	local method=""
	local host=""
	local port=""
	local url=""
	local payload=""
	local certificates_folder=""
	declare -g RAW_RESPONSE
	declare -g RESPONSE

	while [[ $# -gt 0 ]]; do
		case "$1" in
		--method)
			method="$2"
			shift
			;;
		--host)
			host="$2"
			shift
			;;
		--port)
			port="$2"
			shift
			;;
		--url)
			url="$2"
			shift
			;;
		--payload)
			payload="$2"
			shift
			;;
		--certificates-folder)
			certificates_folder="$2"
			shift
			;;
		*) shift ;;
		esac
		shift
	done

	host=${host:-"https://localhost"}
	port=${port:-50001}
	certificates_folder=${certificates_folder:-$CERTIFICATES_FOLDER}

	echo

	COMMAND="curl -s -X \"$method\" \
    --cert \"$certificates_folder/client_cert.pem\" \
    --key \"$certificates_folder/client_key.pem\" \
    --cacert \"$certificates_folder/ca_cert.pem\" \
    --header \"Content-Type: application/json\" \
    -d '$payload' \
    \"$host:$port$url\""

	RAW_RESPONSE=$(docker exec -e method -e certificates_folder -e payload -e host -e port -e url "$CONTAINER_NAME" /bin/bash -c "source /root/.bashrc && $COMMAND" 2>&1)

	if [[ $RAW_RESPONSE == *"is not running"* ]]; then
		CONTAINER_ID=$(echo "$RAW_RESPONSE" | grep -oP 'Container\s+\K[a-f0-9]{12}')
		if [ -n "$CONTAINER_ID" ]; then
			RESPONSE="Fail: Container is not running\n      Container Name: $CONTAINER_NAME\n      Container ID: $CONTAINER_ID"
		fi
	else
		RESPONSE=$(echo "$RAW_RESPONSE" | grep -oP '(?<=:")[^"]*')
	fi
}

fun_client_strategy_start() {
	local strategy=""
	local version=""
	local id=""

	#	while [[ $# -gt 0 ]]; do
	#		case "$1" in
	#			--strategy) strategy="$2"; shift ;;
	#			--version) version="$2"; shift ;;
	#			--id) id="$2"; shift ;;
	#			*) shift ;;
	#		esac
	#		shift
	#	done

	strategy=${strategy:-$STRATEGY}
	version=${version:-$VERSION}
	id=${id:-$ID}

	fun_client_send_request \
		--method "POST" \
		--url "/strategy/start" \
		--payload '{
			"strategy": "'"$strategy"'",
			"version": "'"$version"'",
			"id": "'"$id"'"
		}'
}

fun_client_strategy_stop() {
	local strategy=""
	local version=""
	local id=""

	#	while [[ $# -gt 0 ]]; do
	#		case "$1" in
	#			--strategy) strategy="$2"; shift ;;
	#			--version) version="$2"; shift ;;
	#			--id) id="$2"; shift ;;
	#			*) shift ;;
	#		esac
	#		shift
	#	done

	strategy=${strategy:-$STRATEGY}
	version=${version:-$VERSION}
	id=${id:-$ID}

	fun_client_send_request \
		--method "POST" \
		--url "/strategy/stop" \
		--payload '{
			"strategy": "'"$strategy"'",
			"version": "'"$version"'",
			"id": "'"$id"'"
		}'
}

fun_client_strategy_status() {
	local strategy=""
	local version=""
	local id=""

	#	while [[ $# -gt 0 ]]; do
	#		case "$1" in
	#			--strategy) strategy="$2"; shift ;;
	#			--version) version="$2"; shift ;;
	#			--id) id="$2"; shift ;;
	#			*) shift ;;
	#		esac
	#		shift
	#	done

	strategy=${strategy:-$STRATEGY}
	version=${version:-$VERSION}
	id=${id:-$ID}

	fun_client_send_request \
		--method "GET" \
		--url "/strategy/status" \
		--payload '{
			"strategy": "'"$strategy"'",
			"version": "'"$version"'",
			"id": "'"$id"'"
		}'
}

fun_client_wallet() {
	local method="$1"
	local strategy=""
	local version=""
	local id=""
	local chain="kujira"
	local network="mainnet"
	local connector="kujira"
	local mnemonic=""
	local account_number=0
	local public_key=""

	strategy=${strategy:-$STRATEGY}
	version=${version:-$VERSION}
	id=${id:-$ID}

	if [ "$method" == "POST" ]; then
		while true; do
			echo
			echo "   Enter your Kujira wallet mnemonic"
			echo "   [or type 'back' to return to menu]"
			echo
			read -s -rp "   >>> " mnemonic

			if [ "$mnemonic" == 'back' ]; then
				tput cuu 4
				tput ed
				echo
				return 1
			fi

			if [ -z "$mnemonic" ]; then
				echo
				echo
				echo "      ❌ Invalid mnemonic, please try again."
			else
				# Create an array of words from the mnemonic
				IFS=' ' read -r -a words <<<"$mnemonic"
				num_words="${#words[@]}"
				valid=true

				# Check if number of words is either 12 or 24
				if [ "$num_words" != 12 ] && [ "$num_words" != 24 ]; then
					valid=false
				else
					# Check if each word has at least 2 characters
					for word in "${words[@]}"; do
						if [ ${#word} -lt 2 ]; then
							valid=false
							break
						fi
					done
				fi

				if [ "$valid" = false ]; then
					echo
					echo

					echo "   |      |  Mnemonic must have either 12 or 24 words, with each word having at least 2 characters."
					echo "   |  ❌  |"
					echo "   |      |  example: flag stadium copper carbon slight school fabric verb behave crunch mouse lottery"
					echo
					echo "   Please try again."
				else
					echo
					break
				fi
			fi
		done

		payload='{
			"chain": "'"$chain"'",
			"network": "'"$network"'",
			"connector": "'"$connector"'",
			"privateKey": "'"$mnemonic"'",
			"accountNumber": '"$account_number"'
		}'

		url="/wallet/add"
	elif [ "$method" == "DELETE" ]; then
		while true; do
			echo
			echo "   Enter the public key of the wallet you want to remove "
			echo "   [or type 'back' to return to menu] "
			echo
			read -rp "   >>> " public_key

			if [ "$public_key" == 'back' ]; then
				tput cuu 7
				tput ed
				echo
				return 1
			fi

			if [[ "$public_key" =~ ^kujira[a-z0-9]{39}$ ]]; then
				break
			else
				echo
				echo "   |      |  The wallet public key does not match the expected pattern of starting"
				echo "   |  ❌  |  with 'kujira' followed by 39 lowercase letters and/or numbers."
				echo "   |      |  example: \"kujira18gapnqgd6z6d76z6h360aeklw75uk44qqac0pl\""
				echo
				echo "   Please try again."
			fi
		done

		payload='{
			"chain": "'"$chain"'",
			"address": "'"$public_key"'",
		}'

		url="/wallet/remove"
	fi

	if [[ ! "$mnemonic" == "back" && ! "$public_key" == "back" ]]; then
		fun_client_send_request \
			--method "$method" \
			--url "$url" \
			--payload "$payload"

		return 0
	fi
}

open_on_web_browser() {
	urls=("$@")

	for url in "${urls[@]}"; do
		if [[ "$OSTYPE" == "linux-gnu"* ]]; then
			# If running in WSL
			if grep -qi microsoft /proc/version; then
        cmd.exe /c start "$url" &>/dev/null &
      else
        xdg-open "$url" &>/dev/null &
      fi
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

open_hb_client() {
	docker exec -it "$CONTAINER_NAME" bash -c 'source /root/.bashrc && (start_hb_client; tmux a -t "hb-client")'
}

add_indentation() {
    local var_name=$1
    local spacer=$2
    local new_content=""

    while IFS= read -r line; do
        new_content="${new_content}${spacer}$line\n"
    done <<< "$(eval echo \"\$"$var_name"\")"

    new_content=${new_content%\\n}

    eval "$var_name=\"\$new_content\""
}

actions_submenu() {
	show_menu_options() {
		show_title "BOT CONTROL & WALLET MANAGEMENT"

		echo "   CHOOSE WHICH ACTION YOU WOULD LIKE TO PERFORM:"
		echo
		echo "   [1] START STRATEGY"
		echo "   [2] STOP STRATEGY"
		echo "   [3] STRATEGY STATUS"
		echo "   [4] ADD WALLET"
		echo "   [5] REMOVE WALLET"
		echo "   [6] OPEN HUMMINGBOT CLIENT"
		echo "   [7] OPEN FUNTTASTIC CLIENT"
		echo
		echo "   [back] RETURN TO MAIN MENU"
		echo "   [exit] STOP SCRIPT EXECUTION"
		echo
		echo "   ℹ️  Selected Container: $CONTAINER_NAME"
		echo
	}

	show_menu_options

	while true; do
		read -rp "   Enter your choice (1, 2, 3, 4, 5, 6, 7, back, or exit): " CHOICE

		case $CHOICE in
		1)
			fun_client_strategy_start
			if [ -n "$RESPONSE" ]; then
      	echo -e "      $RESPONSE"
      else
      	echo "      $RAW_RESPONSE"
      fi
			echo
      waiting 3 "   "
			clear
      show_menu_options
			;;
		2)
			fun_client_strategy_stop
			if [ -n "$RESPONSE" ]; then
      	echo -e "      $RESPONSE"
      else
      	echo "      $RAW_RESPONSE"
      fi
      echo
      waiting 3 "   "
			clear
      show_menu_options
			;;
		3)
			fun_client_strategy_status
			if [ -n "$RESPONSE" ]; then
				add_indentation "RESPONSE" "      "
      	echo -e "$RESPONSE"
      else
				add_indentation "RAW_RESPONSE" "      "
      	echo "$RAW_RESPONSE"
      fi
			echo
      waiting 3 "   "
			clear
      show_menu_options
			;;
		4)
			if fun_client_wallet "POST"; then
				echo "      $RAW_RESPONSE"
				echo
				waiting 3 "   "
				clear
        show_menu_options
			fi
			;;
		5)
			if fun_client_wallet "DELETE"; then
				echo "      $RAW_RESPONSE"
				echo
				waiting 3 "   "
				clear
        show_menu_options
			fi
			;;
		6)
			open_hb_client
			clear
      show_menu_options
			;;
		7)
			open_on_web_browser "$FUN_FRONTEND_URL"
			clear
      show_menu_options
			;;
		"back")
			clear
			main_menu
			;;
		"exit")
			exit_application
			exit 0
			;;
		*)
			echo
			echo "      ❌ Invalid Input. Enter your choice (1, 2, 3, 4, 5, back, or exit)."
			echo
			;;
		esac
	done
}

actions_menu() {
	actions_submenu
}

main_menu() {
	show_title "WELCOME TO FUNTTASTIC CLIENT SETUP"
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

	read -rp "   Enter your choice (1, 2, 3, or exit): " CHOICE

	while true; do
		case $CHOICE in
		1)
			install_menu
			break
			;;
		2)
			get_container_name
			restart_all_services

      if [ $? -eq 0 ]; then
          echo
					echo "      ✅ Restarting is complete."
					echo
					waiting 3 "   "
      else
          echo
					echo "      ❌ Failed to restart."
					echo
					waiting 3 "   "
      fi
			break
			;;
		3)
			get_container_name
			set_urls
			actions_menu
			break
			;;
		"exit")
			exit_application
			;;
		*)
			echo
			echo "      ❌ Invalid Input. Enter a your choice (1, 2, 3) or type exit."
			echo
			read -rp "   Enter your choice (1, 2, 3, or exit): " CHOICE
			;;
		esac
	done

	main_menu
}

container_exists() {
	# Accepts a container name or id as the first argument, defaults to CONTAINER_NAME if not provided
	local container_name_or_id="${1:-$CONTAINER_NAME}"
	local is_id="$2"

	# Checks if the specified container exists using docker ps and grep, returns true (0) if found
	if [[ -n "$is_id" && "$is_id" == "TRUE" ]]; then
		docker ps -a --format "{{.ID}}" | grep -wq "$container_name_or_id"
    return $?
	else
		docker ps -a --format "{{.Names}}" | grep -wq "$container_name_or_id"
    return $?
	fi
}

generate_passphrase() {
	local length=$1
	local charset="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
	local passphrase=""
	local charset_length=${#charset}
	local max_random=$((32768 - 32768 % charset_length))

	for ((i = 0; i < length; i++)); do
		while (((random_index = RANDOM) >= max_random)); do :; done
		random_index=$((random_index % charset_length))
		passphrase="${passphrase}${charset:$random_index:1}"
	done

	echo "$passphrase"
}

image_exists() {
	# Accepts an image name as the first argument, defaults to IMAGE_NAME if not provided
	local image_name="${1:-$IMAGE_NAME}"

	# Checks if the specified image exists using docker images and grep, returns true (0) if found
	docker images --format "{{.Repository}}" | grep -wq "$image_name"
	return $?
}

remove_docker_image() {
	# Docker image name
	local image_name=${1:-$IMAGE_NAME}

	# Stop all containers that are using the image
	docker stop "$(docker ps -a -q --filter ancestor="$image_name")" >/dev/null 2>&1

	# Remove all containers that are using the image
	docker rm "$(docker ps -a -q --filter ancestor="$image_name")" >/dev/null 2>&1

	# Remove the image without -f option
	docker rmi "$image_name" >/dev/null 2>&1

	# Check if the image is still present
	if docker images -q "$image_name" >/dev/null 2>&1; then
		# If the image still exists, try removing it with -f option
		docker rmi -f "$image_name" >/dev/null 2>&1
	fi
}

docker_prune_selectively() {
	local target_image_name="${1:-$IMAGE_NAME}"
	local target_image_id

	target_image_id=$(docker images | grep "$target_image_name" | awk '{print $3}')

	local temp_containers=()
	local image_ids

	image_ids=$(docker images -q)

	for image_id in $image_ids; do
		if [ ! "$image_id" == "$target_image_id" ]; then
			container=$(docker create "$image_id")
			temp_containers+=("$container")
		else
			container_ids=$(docker ps -a --filter "ancestor=$image_id" -q)
			for container_id in $container_ids; do
				docker stop "$container_id" &>/dev/null
				docker rm -f "$container_id" &>/dev/null
			done

			docker rmi -f "$target_image_id" &>/dev/null
		fi
	done

	local all_stopped_containers

	all_stopped_containers=$(docker ps -a --filter "status=exited" -q)
	for container_id in $all_stopped_containers; do
		docker start "$container_id" &>/dev/null &
	done

	docker system prune -a -f --volumes &>/dev/null

	for container in "${temp_containers[@]}"; do
		docker rm -f "$container" &>/dev/null
	done

	# If there is a container related to this project running, even if the
	# container name is different, it will cause some applications to be
	# unable to start because some ports, such as 50000, 50001, and 50002,
	# are already in use. To try to avoid this as much as possible,
	# pre-existing containers started in one of the steps above will be stopped.
	for container_id in $all_stopped_containers; do
		docker stop "$container_id" &>/dev/null &
	done
}

remove_docker_container() {
	# Docker container name or ID
	local container_name_or_id=${1:-$CONTAINER_NAME}

	# Stops the specified container if it's running
	docker stop "$container_name_or_id" >/dev/null 2>&1

	# Removes the specified container
	docker rm "$container_name_or_id" >/dev/null 2>&1
}

prompt_proceed() {
	while true; do
		echo
		echo "   ℹ️  Enter 'restart' to restart all process or 'exit' to exit script."
		echo
		read -rp "   Do you want to proceed? [Y/n] >>> " RESPONSE

		if [[ "$RESPONSE" == "Y" || "$RESPONSE" == "y" || \
          "$RESPONSE" == "Yes" || "$RESPONSE" == "yes" || \
          "$RESPONSE" == "" ||  \
          "$RESPONSE" == "N" || "$RESPONSE" == "n" || \
          "$RESPONSE" == "No" || "$RESPONSE" == "no" || \
          "$RESPONSE" == "restart" || "$RESPONSE" == "exit" ]]; then
			break
		else
			tput cuu 4
			tput ed
		fi
	done

	if [[ "$RESPONSE" == "Y" || "$RESPONSE" == "y" || "$RESPONSE" == "Yes" || "$RESPONSE" == "yes" || "$RESPONSE" == "" ]]; then
		PROCEED="Y"
	fi

	if [[ "$RESPONSE" == "restart" ]]; then
		install_menu
	fi

	if [[ "$RESPONSE" == "exit" ]]; then
		exit_application
	fi
}

default_values_info() {
	echo
	echo "   ℹ️  Press [ENTER] for default values:"
	echo
}

docker_create_image() {
	if [ "$EXPOSE_HB_GATEWAY_PORT" == "TRUE" ]; then
		sed -i "s/#EXPOSE $HB_GATEWAY_PORT/EXPOSE $HB_GATEWAY_PORT/g" Dockerfile
	fi

	if [[ "$AUTO_SIGNIN" == "TRUE" && -n "$SSH_PUBLIC_KEY_HOST_PATH" && -n "$SSH_PRIVATE_KEY_HOST_PATH" ]]; then
		sed -i -e "/COPY \$SSH_PUBLIC_KEY_HOST_PATH \/root\/.ssh/ s/^#//" ./Dockerfile
		sed -i -e "/COPY \$SSH_PRIVATE_KEY_HOST_PATH \/root\/.ssh/ s/^#//" ./Dockerfile
	fi

	if [ ! "$BUILD_CACHE" == "" ]; then
		BUILT=$(DOCKER_BUILDKIT=1 docker build \
			--build-arg ADMIN_USERNAME="$ADMIN_USERNAME" \
			--build-arg ADMIN_PASSWORD="$ADMIN_PASSWORD" \
			--build-arg AUTO_SIGNIN="$AUTO_SIGNIN" \
			--build-arg HB_GATEWAY_PASSPHRASE="$ADMIN_PASSWORD" \
			--build-arg FUN_CLIENT_REPOSITORY_URL="$FUN_CLIENT_REPOSITORY_URL" \
			--build-arg FUN_CLIENT_REPOSITORY_BRANCH="$FUN_CLIENT_REPOSITORY_BRANCH" \
			--build-arg HB_CLIENT_REPOSITORY_URL="$HB_CLIENT_REPOSITORY_URL" \
			--build-arg HB_CLIENT_REPOSITORY_BRANCH="$HB_CLIENT_REPOSITORY_BRANCH" \
			--build-arg HB_GATEWAY_REPOSITORY_URL="$HB_GATEWAY_REPOSITORY_URL" \
			--build-arg HB_GATEWAY_REPOSITORY_BRANCH="$HB_GATEWAY_REPOSITORY_BRANCH" \
			--build-arg HOST_USER_GROUP="$GROUP" \
			--build-arg LOCK_APT="$LOCK_APT" \
			--build-arg FUN_FRONTEND_PORT="$FUN_FRONTEND_PORT" \
			--build-arg FILEBROWSER_PORT="$FILEBROWSER_PORT" \
			--build-arg FUN_CLIENT_PORT="$FUN_CLIENT_PORT" \
			--build-arg HB_GATEWAY_PORT="$HB_GATEWAY_PORT" \
			--build-arg FUN_FRONTEND_COMMAND="$FUN_FRONTEND_COMMAND" \
			--build-arg FILEBROWSER_COMMAND="$FILEBROWSER_COMMAND" \
			--build-arg FUN_CLIENT_COMMAND="$FUN_CLIENT_COMMAND" \
			--build-arg HB_GATEWAY_COMMAND="$HB_GATEWAY_COMMAND" \
			--build-arg HB_CLIENT_COMMAND="$HB_CLIENT_COMMAND" \
			-t "$IMAGE_NAME" -f ./Dockerfile .)

		if grep -iq "ERROR" <<< "$BUILT" || ! image_exists "$IMAGE_NAME"; then
				echo
				echo "   |¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|"
				echo "   |  ❌  An error occurred while building the Docker image. |"
				echo "   |                                                         |"
				echo "   |  This can occur for several reasons. Please try again!  |"
				echo "   |                                                         |"
				echo "   |  If even trying again fails, please copy the error      | "
				echo "   |  log and report it on our Discord server:               |"
				echo "   |                                                         |"
				echo "   |      http://www.funttastic.com/discord                  |"
				echo "   |_________________________________________________________|"
				echo
				echo
				read -s -n1 -rp "   Press any key to return to the main menu >>> "
				main_menu
		fi
	fi
}

docker_create_container() {
	$BUILT &&
		COMPLETE_CONTAINER_ID=$(docker run \
    			-dit \
    			--log-opt max-size=10m \
    			--log-opt max-file=5 \
    			--name "$CONTAINER_NAME" \
    			--network "$NETWORK" \
    			--mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
    			-e FUN_CLIENT_RESOURCES_FOLDER="/root/funttastic/client/resources" \
    			-e HB_CLIENT_CONF_FOLDER="/root/hummingbot/client/conf" \
    			-e HB_CLIENT_LOGS_FOLDER="/root/hummingbot/client/logs" \
    			-e HB_CLIENT_DATA_FOLDER="/root/hummingbot/client/data" \
    			-e HB_CLIENT_SCRIPTS_FOLDER="/root/hummingbot/client/scripts" \
    			-e HB_CLIENT_PMM_SCRIPTS_FOLDER="/root/hummingbot/client/pmm_scripts" \
    			-e HB_GATEWAY_CONF_FOLDER="/root/hummingbot/gateway/conf" \
    			-e HB_GATEWAY_LOGS_FOLDER="/root/hummingbot/gateway/logs" \
    			-p "$FUN_FRONTEND_PORT":"$FUN_FRONTEND_PORT" \
    			-p "$FILEBROWSER_PORT":"$FILEBROWSER_PORT" \
    			$ENTRYPOINT \
    			"$IMAGE_NAME":$TAG)

	CONTAINER_ID=${COMPLETE_CONTAINER_ID:0:12}

	if container_exists "$CONTAINER_ID" "TRUE"; then
		return 0
	else
		return 1
	fi
}

post_installation() {
	waiting 3

	if [ "$OPEN_IN_BROWSER" = "TRUE" ]; then
		open_on_web_browser "$FUN_FRONTEND_URL"
	fi

	if [ "$HB_CLIENT_ATTACH" = "TRUE" ]; then
		open_hb_client
	fi
}

installation() {
	docker_create_image
	if docker_create_container; then
		post_installation
	fi
}

execute_installation() {
	case $CHOICE in
	"ALL")
		echo
		echo "   Installing:"
		echo
		echo "     > Funttastic Client Server"
		echo "     > Funttastic Client Frontend"
		echo "     > Hummingbot Client"
		echo "     > Hummingbot Gateway"
		echo "     > FileBrowser"
		echo
		echo "     ℹ️  All in just one container."
		echo

		installation
		;;
	esac
}

install_docker() {
	if [ "$(command -v docker)" ]; then
		execute_installation
	else
		echo "   Docker is not installed."
		echo "   Installing Docker will require superuser permissions."
		read -rp "   Do you want to continue? [y/N] >>> " RESPONSE
		echo

		if [[ "$RESPONSE" == "Y" || "$RESPONSE" == "y" ]]; then
			sudo echo
			echo "Docker installation started."
			echo

			case $(uname | tr '[:upper:]' '[:lower:]') in
			linux*)
				OS="Linux"

				# Installation for Debian-based distributions (like Ubuntu)
				if [ -f /etc/debian_version ]; then
					# Update and install prerequisites
					sudo apt-get update
					sudo apt-get install -y ca-certificates curl gnupg
					sudo install -m 0755 -d /etc/apt/keyrings

					# Add Docker's official GPG key
					curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
					sudo chmod a+r /etc/apt/keyrings/docker.gpg

					# Set up the stable repository
					echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME")" stable | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

					# Install Docker Engine
					sudo apt-get update
					sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
				elif [ -f /etc/redhat-release ]; then
					# Installation for Red Hat-based distributions (like CentOS)
					sudo yum install -y yum-utils
					sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
					sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
				else
					echo "   Unsupported Linux distribution"
					exit 1
				fi

				sudo groupadd -f docker
				sudo usermod -aG docker "$USER"
				sudo chmod 666 /var/run/docker.sock
				sudo systemctl restart docker
				;;
			darwin*)
				# Installation of Docker for macOS
				OS="MacOSX"

				curl -L "https://download.docker.com/mac/stable/Docker.dmg" -o /tmp/Docker.dmg
				hdiutil attach /tmp/Docker.dmg
				cp -R /Volumes/Docker/Docker.app /Applications
				hdiutil detach /Volumes/Docker
				;;
			msys* | cygwin* | mingw*)
				# Installation of Docker for Windows (assuming in an environment like Git Bash)
				OS="Windows"

				echo "   To install Docker on Windows, please download and install manually from: https://hub.docker.com/editions/community/docker-ce-desktop-windows/"
				;;
			*)
				echo "   Unrecognized operating system"
				exit 1
				;;
			esac

			echo "Operating System: $OS"
			echo "Architecture: $(uname -m)"

			echo
			echo "Docker installation is finished."
			echo

			execute_installation
		else
			echo
			echo "   Script execution aborted."
			echo
		fi
	fi
}
