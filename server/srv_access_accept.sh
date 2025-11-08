#!/bin/bash


# This script for accepting the access code that will be send the clinet 

# First: you need to check the required arguments that will come from the client VM side if they exists
# -z will check if a string is empty, we want to check all exists
if [ -z "$client_user" ] || [ -z "$access_code" ] || [ -z "$fname" ]; then
	echo "You should provide the client user, the access code, and the file name"
	exit 1
fi


# Second: Check if the access code from the client matches an access code in allowlist.txt

allowList=~/tokens/allowlist.txt

# If the access code is not in the allow list file exit

if [ ! grep "$access_code" "$allowList" ]; then
	
	echo "REJECT invalid_token"
	exit 1
fi

# Third: Generate a requesit id to track each job
# $RANDOM will give you a random 4 digits number 
REQ_ID="REQ_$(date +%Y%m%d_%H%M%S)_$RANDOM"

mkdir ~/queue

# Fourth: Now we need to create the request file
# 1- Create a variable that hold the path that from REQ_ID to make the request file
request_file=~/queue/${REQ_ID}.req

# 2- Now create the file 
touch "$request_file"


# Fifth: Now write to the file 

echo "ID=$REQ_ID" > "$request_file"


# Now use >> to append and not overwrites 
echo "CLIENT_USER=$client_user" >> "$request_file"
echo "CREATED_UTC=$(date -u +"%Y-%m-%dT%H:%M:%S")" >> "$request_file"
echo "PAYLOAD_FILE=${request_file}.payload" >> "$request_file"
echo "FILENAME=$fname"


# Sixth: send verification to the client 
echo "ACCEPT $REQ_ID"