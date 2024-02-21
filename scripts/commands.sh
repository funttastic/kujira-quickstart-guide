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

	strategy=${strategy:-$STRATEGY}
	version=${version:-$VERSION}
	id=${id:-$ID}

	if [ "$method" == "POST" ]; then
		while true; do
			echo
			read -s -rp "   Enter your Kujira wallet mnemonic
   [or type 'back' to return to menu] >>> " mnemonic

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

					echo "      |      |  Mnemonic must have either 12 or 24 words, with each word having at least 2 characters."
					echo "      |  ❌  |"
					echo "      |      |  example: flag stadium copper carbon slight school fabric verb behave crunch mouse lottery"
				else
					echo
					break
				fi
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
	elif [ "$method" == "DELETE" ]; then
		while true; do
			echo
			read -rp "   Enter the public key of the wallet you want to remove
   [or type 'back' to return to menu] >>> " public_key

			if [ "$public_key" == 'back' ]; then
				tput cuu 5
				tput ed
				echo
				return 1
			fi

			if [[ "$public_key" =~ ^kujira[a-z0-9]{39}$ ]]; then
				break
			else
				echo
				echo "      |      |  The wallet public key does not match the expected pattern of starting"
				echo "      |  ❌  |  with 'kujira' followed by 39 lowercase letters and/or numbers."
				echo "      |      |  example: \"kujira2q7kr0ffptrkq1hg8hhq71vqxex3kj6refy7sf6\""
				echo
				echo "      Please try again."
			fi
		done

		payload="{
              \"chain\": \"$chain\",
              \"address\": \"$public_key\"
            }"

		url="/wallet/remove"
	fi

	if [[ ! "$mnemonic" == "back" && ! "$public_key" == "back" ]]; then
		send_request \
			--method "$method" \
			--url "$url" \
			--payload "$payload"

		return 0
	fi
}

open_hb_client() {
	docker attach $CONTAINER_NAME
}

more_information() {
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
	echo "   [6] OPEN HUMMINGBOT CLIENT"
	echo
	echo "   [back] RETURN TO MAIN MENU"
	echo "   [exit] STOP SCRIPT EXECUTION"
	echo
	more_information
	echo

	while true; do
		read -rp "   Enter your choice (1, 2, 3, 4, 5, 6, back, or exit): " CHOICE

		case $CHOICE in
		1)
			start
			echo -e "      $RESPONSE"
			echo
			;;
		2)
			stop
			echo -e "      $RESPONSE"
			echo
			;;
		3)
			status
			echo -e "      $RESPONSE"
			echo
			;;
		4)
			if wallet "POST"; then
				echo "      $RAW_RESPONSE"
				echo
			fi
			;;
		5)
			if wallet "DELETE"; then
				echo "      $RAW_RESPONSE"
				echo
			fi
			;;
		6)
			open_hb_client
			echo -e "      $RESPONSE"
			echo
			;;
		"back")
			clear
			./configure
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
			echo "      ❌ Invalid Input. Enter your choice (1, 2, 3, 4, 5, back, or exit)."
			echo
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
