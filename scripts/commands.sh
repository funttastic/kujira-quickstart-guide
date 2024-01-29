#!/bin/bash

SCRIPT_DIR=$(dirname "$0")
SCRIPT_NAME="$(basename "$0")"
SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT_NAME"

CONTAINER_NAME="fun-kuji-hb"

HOST=https://localhost
PORT=50001

STRATEGY="pure_market_making"
VERSION="1.0.0"
ID="default"

# Inside the container
CERTIFICATES_FOLDER="/root/shared/common/certificates"

send_request() {
	local method=""
	local host=""
	local port=""
	local url=""
	local payload=""
	local certificates_folder=""

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

  COMMAND="curl -X \"$method\" \
    --cert \"$certificates_folder/client_cert.pem\" \
    --key \"$certificates_folder/client_key.pem\" \
    --cacert \"$certificates_folder/ca_cert.pem\" \
    --header \"Content-Type: application/json\" \
    -d \"$payload\" \
    \"$host:$port$url\""

  docker exec -e method -e certificates_folder -e payload -e host -e port -e url $CONTAINER_NAME /bin/bash -c "$COMMAND"

	echo
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
        echo -e "\n\n   ℹ️ Returning to the menu..."
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
        echo -e "\n   ℹ️ Returning to the menu..."
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
    clear
    echo
    echo "   ==========      BOT CONTROL -> FUNTTASTIC CLIENT / GATEWAY      =========="
    echo
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
                sleep 3
                clear
                exec "$SCRIPT_PATH"
                break
                ;;
            2)
                stop
                sleep 3
                clear
                exec "$SCRIPT_PATH"
                break
                ;;
            3)
                status
                sleep 3
                clear
                exec "$SCRIPT_PATH"
                break
                ;;
            4)
                wallet "POST"
                sleep 3
                clear
                exec "$SCRIPT_PATH"
                break
                ;;
            5)
                wallet "DELETE"
                sleep 3
                clear
                exec "$SCRIPT_PATH"
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

# =====================================================================================================================

choose