#!/bin/bash

clear

source /home/user/.bashrc

stop
start
sleep 2

export USERNAME=<username>
export PASSWORD=<password>
export DOMAIN1=localhost
export DOMAIN2=<domain2>

export DOMAIN=$DOMAIN1
echo "=========================================================================="
echo "=========================================================================="
echo "DOMAIN: $DOMAIN"
echo "=========================================================================="
echo "=========================================================================="

export HOST=$DOMAIN
export REST_PROTOCOL=http
export WEBSOCKET_PROTOCOL=ws

conda activate funttastic

echo -e "\n"
echo "=========================================================================="
echo "Filebrowser:"
echo "=========================================================================="

echo -e "\n"
echo "--------------------------------------------------------------------------"
echo "HTTP:"
echo "--------------------------------------------------------------------------"
curl \
	--cacert "/home/user/funttastic/client/resources/certificates/ca_cert.pem" \
	http://$DOMAIN/filebrowser

echo -e "\n"
echo "--------------------------------------------------------------------------"
echo "HTTPS:"
echo "--------------------------------------------------------------------------"
curl \
	--cacert "/home/user/funttastic/client/resources/certificates/ca_cert.pem" \
	https://$DOMAIN/filebrowser

echo -e "\n"
echo "=========================================================================="
echo "Frontend:"
echo "=========================================================================="

echo -e "\n"
echo "--------------------------------------------------------------------------"
echo "HTTP:"
echo "--------------------------------------------------------------------------"
curl \
	--cacert "/home/user/funttastic/client/resources/certificates/ca_cert.pem" \
	http://$DOMAIN

echo -e "\n"
echo "--------------------------------------------------------------------------"
echo "HTTPS:"
echo "--------------------------------------------------------------------------"
curl \
	--cacert "/home/user/funttastic/client/resources/certificates/ca_cert.pem" \
	https://$DOMAIN

echo -e "\n"
echo "=========================================================================="
echo "API:"
echo "=========================================================================="

echo -e "\n"
echo "--------------------------------------------------------------------------"
echo "HTTP:"
echo "--------------------------------------------------------------------------"
curl -X "POST" \
	--cert "/home/user/funttastic/client/resources/certificates/client_cert.pem" \
	--key "/home/user/funttastic/client/resources/certificates/client_key.pem" \
	--cacert "/home/user/funttastic/client/resources/certificates/ca_cert.pem" \
	--header "Content-Type: application/json" \
	-d "{\"username\": \"$USERNAME\", \"password\": \"$PASSWORD\"}" \
	"http://$DOMAIN/api/auth/signIn"

echo -e "\n"
echo "--------------------------------------------------------------------------"
echo "HTTPS:"
echo "--------------------------------------------------------------------------"
curl -X "POST" \
	--cert "/home/user/funttastic/client/resources/certificates/client_cert.pem" \
	--key "/home/user/funttastic/client/resources/certificates/client_key.pem" \
	--cacert "/home/user/funttastic/client/resources/certificates/ca_cert.pem" \
	--header "Content-Type: application/json" \
	-d "{\"username\": \"$USERNAME\", \"password\": \"$PASSWORD\"}" \
	"https://$DOMAIN/api/auth/signIn"

echo -e "\n"
echo "=========================================================================="
echo "WebSocket:"
echo "=========================================================================="

# echo -e "\n"
# echo "WS:"
# export REST_PROTOCOL=http
# export WEBSOCKET_PROTOCOL=ws
# cd /home/user/funttastic/client/resources/scripts
# export PORT=80
# timeout 2s python test_websocket_logs.py
# unset PORT

echo -e "\n"
echo "--------------------------------------------------------------------------"
echo "WSS:"
echo "--------------------------------------------------------------------------"
export REST_PROTOCOL=https
export WEBSOCKET_PROTOCOL=wss
export PORT=443
cd /home/user/funttastic/client/resources/scripts
timeout 2s python test_websocket_logs.py
unset PORT


export DOMAIN=$DOMAIN2
echo -e "\n\n"
echo "=========================================================================="
echo "=========================================================================="
echo "DOMAIN: $DOMAIN"
echo "=========================================================================="
echo "=========================================================================="

export HOST=$DOMAIN
export REST_PROTOCOL=http
export WEBSOCKET_PROTOCOL=ws

stop
start
sleep 2

conda activate funttastic

echo -e "\n"
echo "=========================================================================="
echo "Filebrowser:"
echo "=========================================================================="

echo -e "\n"
echo "--------------------------------------------------------------------------"
echo "HTTP:"
echo "--------------------------------------------------------------------------"
curl http://$DOMAIN/filebrowser

echo -e "\n"
echo "--------------------------------------------------------------------------"
echo "HTTPS:"
echo "--------------------------------------------------------------------------"
curl https://$DOMAIN/filebrowser

echo -e "\n"
echo "=========================================================================="
echo "Frontend:"
echo "=========================================================================="

echo -e "\n"
echo "--------------------------------------------------------------------------"
echo "HTTP:"
echo "--------------------------------------------------------------------------"
curl http://$DOMAIN

echo -e "\n"
echo "--------------------------------------------------------------------------"
echo "HTTPS:"
echo "--------------------------------------------------------------------------"
curl https://$DOMAIN

echo -e "\n"
echo "=========================================================================="
echo "API:"
echo "=========================================================================="

echo -e "\n"
echo "--------------------------------------------------------------------------"
echo "HTTP:"
echo "--------------------------------------------------------------------------"
curl -X "POST" \
	--cert "/home/user/funttastic/client/resources/certificates/client_cert.pem" \
	--key "/home/user/funttastic/client/resources/certificates/client_key.pem" \
	--cacert "/home/user/funttastic/client/resources/certificates/ca_cert.pem" \
	--header "Content-Type: application/json" \
	-d "{\"username\": \"$USERNAME\", \"password\": \"$PASSWORD\"}" \
	"http://$DOMAIN/api/auth/signIn"

echo -e "\n"
echo "--------------------------------------------------------------------------"
echo "HTTPS:"
echo "--------------------------------------------------------------------------"
curl -X "POST" \
	--cert "/home/user/funttastic/client/resources/certificates/client_cert.pem" \
	--key "/home/user/funttastic/client/resources/certificates/client_key.pem" \
	--cacert "/home/user/funttastic/client/resources/certificates/ca_cert.pem" \
	--header "Content-Type: application/json" \
	-d "{\"username\": \"$USERNAME\", \"password\": \"$PASSWORD\"}" \
	"https://$DOMAIN/api/auth/signIn"

echo -e "\n"
echo "=========================================================================="
echo "WebSocket:"
echo "=========================================================================="

# echo -e "\n"
# echo "WS:"
# export REST_PROTOCOL=http
# export WEBSOCKET_PROTOCOL=ws
# export PORT=80
# cd /home/user/funttastic/client/resources/scripts
# timeout 2s python test_websocket_logs.py
# unset PORT

echo -e "\n"
echo "--------------------------------------------------------------------------"
echo "WSS:"
echo "--------------------------------------------------------------------------"
export REST_PROTOCOL=https
export WEBSOCKET_PROTOCOL=wss
export PORT=443
cd /home/user/funttastic/client/resources/scripts
timeout 2s python test_websocket_logs.py
unset PORT
