#!/bin/bash

SCRIPT_DIR=$(dirname "$0")
SCRIPT_NAME="$(basename "$0")"
SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT_NAME"

HOST=https://localhost
PORT=50001

STRATEGY="pure_market_making"
VERSION="1.0.0"
ID="default"

# Inside the container
CERTIFICATES_FOLDER="/root/shared/common/certificates"

show_title() {
		clear
		echo
		echo "   ========================   BOT CONTROL & WALLET MANAGEMENT   ========================"
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

		echo "   ℹ️  Before you can send commands, we need to choose the destination container."
		echo

    while true; do
        if [ -n "$CONTAINER_NAME" ]; then
        		echo "   Enter the container name (was found: \"$CONTAINER_NAME\")"

						echo
						echo "   [Press Enter to use '$CONTAINER_NAME' or enter 'back' to return to main menu]"
						echo
        else
        		echo "   Enter the container name (example: \"fun-kuji-hb\"):"
        		echo
        		echo "   [Enter 'back' to return to main menu]"
        		echo
        fi

        read -rp "   >>> " input_name

				if [ -n "$CONTAINER_NAME" ]; then
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

                if [ "$input_name" == "back" ]; then
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

                if [ "$input_name" == "back" ]; then
                    return 1
                fi
            done
        fi
    done
}

send_request() {
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
			--method) method="$2"; shift ;;
			--host) host="$2"; shift ;;
			--port) port="$2"; shift ;;
			--url) url="$2"; shift ;;
			--payload) payload="$2"; shift ;;
			--certificates-folder) certificates_folder="$2"; shift ;;
			*) shift ;;
		esac
		shift
	done

	host=${host:-$HOST}
	port=${port:-$PORT}
	certificates_folder=${certificates_folder:-$CERTIFICATES_FOLDER}

	echo

  COMMAND="curl -s -X \"$method\" \
    --cert \"$certificates_folder/client_cert.pem\" \
    --key \"$certificates_folder/client_key.pem\" \
    --cacert \"$certificates_folder/ca_cert.pem\" \
    --header \"Content-Type: application/json\" \
    -d \"$payload\" \
    \"$host:$port$url\""

  RAW_RESPONSE=$(docker exec -e method -e certificates_folder -e payload -e host -e port -e url "$CONTAINER_NAME" /bin/bash -c "source /root/.bashrc && $COMMAND")

  RESPONSE=$(echo "$RAW_RESPONSE" | grep -oP '(?<=:")[^"]*')
}

start() {
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

	send_request \
	--method "POST" \
	--url "/strategy/start" \
	--payload "{
		\"strategy\": \"$strategy\",
		\"version\": \"$version\",
		\"id\": \"$id\"
	}"
}

stop() {
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

	send_request \
	--method "POST" \
	--url "/strategy/stop" \
	--payload "{
		\"strategy\": \"$strategy\",
		\"version\": \"$version\",
		\"id\": \"$id\"
	}"
}

status() {
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

	send_request \
	--method "POST" \
	--url "/strategy/status" \
	--payload "{
		\"strategy\": \"$strategy\",
		\"version\": \"$version\",
		\"id\": \"$id\"
	}"
}

wallet() {
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

  if [ "$method" == "POST" ]; then
    while true; do
      echo
      read -s -rp "   Enter your Kujira wallet mnemonic
   [or type 'back' to return to menu] >>> " mnemonic

      if [ "$mnemonic" == 'back' ]; then
        echo -e "\n\n      ℹ️  Returning to the menu..."
        echo
        break
      fi

      if [ -z "$mnemonic" ]; then
        echo
        echo
        echo "      ❌ Invalid mnemonic, please try again."
      else
        echo
        break
      fi
    done

    payload="{
              \"chain\": \"$chain\",
              \"network\": \"$network\",
              \"connector\": \"$connector\",
              \"privateKey\": \"$mnemonic\",
              \"accountNumber\": $account_number
            }"

    url="/wallet/add"
  elif [  "$method" == "DELETE"  ]; then
    while true; do
      echo
      read -rp "   Enter the public key of the wallet you want to remove
   [or type 'back' to return to menu] >>> " public_key

      if [ "$public_key" == 'back' ]; then
        echo -e "\n      ℹ️  Returning to the menu..."
        echo
        break
      fi

      if [ -z "$public_key" ]; then
        echo
        echo "      ❌ Invalid account public key, please try again."
      else
        echo
        break
      fi
    done

    payload="{
              \"chain\": \"$chain\",
              \"address\": \"$public_key\"
            }"

    url="/wallet/remove"
  fi

  if [[ "$method" == "POST" && ! "$mnemonic" == "back" || "$method" == "DELETE" && ! "$public_key" == "back" ]]; then
    send_request \
    --method "$method" \
    --url "$url" \
    --payload "$payload"
  fi
}

more_information(){
  echo "   For more information about the FUNTTASTIC CLIENT, please visit:"
  echo
  echo "      https://www.funttastic.com/partners/kujira"
}

choose() {
		show_title

    echo "   CHOOSE WHICH ACTION YOU WOULD LIKE TO PERFORM:"
    echo
    echo "   [1] START"
    echo "   [2] STOP"
    echo "   [3] STATUS"
    echo "   [4] ADD WALLET"
    echo "   [5] REMOVE WALLET"
    echo
    echo "   [back] RETURN TO MAIN MENU"
    echo "   [exit] STOP SCRIPT EXECUTION"
    echo
    more_information
    echo

    read -rp "   Enter your choice (1, 2, 3, 4, 5, back or exit): " CHOICE

    clear

    while true; do
        case $CHOICE in
            1)
                start
                echo "      $RESPONSE"

                echo
                read -s -n1 -rp "   Press any key to return to previous menu >>> "
                clear
                if [ -n "$CONTAINER_NAME" ]; then
                		(echo "$CONTAINER_NAME"; cat -) | exec "$SCRIPT_PATH"
                else
                		exec "$SCRIPT_PATH"
                fi
                break
                ;;
            2)
                stop
                echo "      $RESPONSE"

                echo
                read -s -n1 -rp "   Press any key to return to previous menu >>> "
                clear
                if [ -n "$CONTAINER_NAME" ]; then
                		(echo "$CONTAINER_NAME"; cat -) | exec "$SCRIPT_PATH"
                else
                		exec "$SCRIPT_PATH"
                fi
                break
                ;;
            3)
                status
                echo "      Status: $RESPONSE"

                echo
                read -s -n1 -rp "   Press any key to return to previous menu >>> "
                clear
                if [ -n "$CONTAINER_NAME" ]; then
                		(echo "$CONTAINER_NAME"; cat -) | exec "$SCRIPT_PATH"
                else
                		exec "$SCRIPT_PATH"
                fi
                break
                ;;
            4)
                wallet "POST"
                echo "      $RAW_RESPONSE"

                echo
                read -s -n1 -rp "   Press any key to return to previous menu >>> "
                clear
                if [ -n "$CONTAINER_NAME" ]; then
                		(echo "$CONTAINER_NAME"; cat -) | exec "$SCRIPT_PATH"
                else
                		exec "$SCRIPT_PATH"
                fi
                break
                ;;
            5)
                wallet "DELETE"
                echo "      $RAW_RESPONSE"

                echo
                read -s -n1 -rp "   Press any key to return to previous menu >>> "
                clear
                if [ -n "$CONTAINER_NAME" ]; then
                		(echo "$CONTAINER_NAME"; cat -) | exec "$SCRIPT_PATH"
                else
                		exec "$SCRIPT_PATH"
                fi
                break
                ;;
            "back")
                clear
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
                echo "      ❌ Invalid Input. Enter a your choice (1, 2, 3, 4) or type back or exit."
                echo
                read -rp "   Enter your choice (1, 2, 3, 4, 5, back, or exit): " CHOICE
                ;;
        esac
    done
}

select_target_container() {
		if get_container_name; then
				choose
		else
			  ./configure
		fi
}

select_target_container
