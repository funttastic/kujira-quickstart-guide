#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
CERTIFICATES_FOLDER=$(readlink -f "$SCRIPT_DIR/../shared/common/certificates")

HOST=https://localhost
PORT=5000

STRATEGY="pure_market_making"
VERSION="1.0.0"
ID="id"

DIR_NAME=$(dirname "$0")
SCRIPT_NAME="$(basename "$0")"
SCRIPT_RELATIVE_PATH="$DIR_NAME/$SCRIPT_NAME"

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

	curl -X "$method" \
		--cert "$certificates_folder/client_cert.pem" \
		--key "$certificates_folder/client_key.pem" \
		--cacert "$certificates_folder/ca_cert.pem" \
		--header "Content-Type: application/json" \
		-d "$payload" \
		"$host:$port$url"

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
      read -s -rp "   Enter your Kujira wallet mnemonic >>> " mnemonic
      if [ -z "$mnemonic" ]; then
        echo
        echo
        echo "      Invalid mnemonic, please try again."
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
      read -rp "   Enter the public key of the wallet you want to remove >>> " public_key
      if [ -z "$public_key" ]; then
        echo
        echo
        echo "      Invalid account public key, please try again."
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

#  echo "$payload"

	send_request \
	--method "$method" \
	--url "$url" \
	--payload "$payload"
}

choose() {
    echo
    echo "   ===============     WELCOME TO FUNTTASTIC HUMMINGBOT CLIENT SETUP     ==============="
    echo
    echo "   CHOOSE WHICH ACTION YOU WOULD LIKE TO PERFORM:"
    echo
    echo "   [1] START"
    echo "   [2] STOP"
    echo "   [3] STATUS"
    echo "   [4] ADD WALLET"
    echo "   [5] REMOVE WALLET"
    echo
    echo "   [0] RETURN TO MAIN MENU"
    echo "   [exit] STOP SCRIPT EXECUTION"
    echo
    echo "   For more information about the FUNTTASTIC HUMMINGBOT CLIENT, please visit:"
    echo
    echo "         https://www.funttastic.com/partners/kujira"
    echo

    read -rp "   Enter your choice (1-5): " CHOICE

    while true; do
        case $CHOICE in
            1)
                start
                sleep 3
                clear
                exec "$SCRIPT_RELATIVE_PATH"
                break
                ;;
            2)
                stop
                sleep 3
                clear
                exec "$SCRIPT_RELATIVE_PATH"
                break
                ;;
            3)
                status
                sleep 3
                clear
                exec "$SCRIPT_RELATIVE_PATH"
                break
                ;;
            4)
                wallet "POST"
                sleep 3
                clear
                exec "$SCRIPT_RELATIVE_PATH"
                break
                ;;
            5)
                wallet "DELETE"
                sleep 3
                clear
                exec "$SCRIPT_RELATIVE_PATH"
                break
                ;;
            0)
                clear
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
                echo "   Invalid Input. Enter a number between 1 and 4."
                read -rp "   Enter your choice (1-4): " CHOICE
                ;;
        esac
    done
}

# =====================================================================================================================

choose