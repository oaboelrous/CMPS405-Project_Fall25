#!/bin/bash


# Step 1: Get arguments
server_host=$1
req_id=$2

# Check if the user added the 2 arguments 
if [ $# -ne 2 ]; then
    echo "You should provide 2 arguments: server hostname, request ID"
    exit 1
fi



# Step 2: Check if result file exists on server
result_path="\$HOME/results/RES_${req_id}.txt" # the path of the result file (in the server side)
request_path="\$HOME/queue/${req_id}.req" # the path of the request file (in the server side)
payload_path="\$HOME/queue/${req_id}.payload" # the path of the payload file (in the server side)


# Step 3: Check if the result file exitsts
ssh "$server_host" "test -f $result_path" # test -f here means check if the file exists
# test command will reutrn 0 if true and 1 if false

result_exitst=$? # $? will return the exit code of the last command that was run (which is test -f)

if [ $result_exitst -eq 0 ]; then
	
	# Step 4: Copy the result file from the server to the client 
	scp "$server_host:$result_path" ~/results/${req_id}.txt
	
	# Step 5: Print confirmation
	echo "READY results/${req_id}.txt"
	
	
else

	# Step 6: Check if still processing
	
	# 6.1: check if the request file exists 
	ssh "$server_host" "test -f $request_path"
	request_exists=$? # 0 --> means true
	
	
	# 6.2: Check if the payload file exists
	ssh "$server_host" "test -f $payload_path"
	payload_exists=$? # 0 --> means true 
	
	
	# Check if either of the files exists
	# I have added [[]] because i was getting an error with []
	if [[ $request_exists -eq 0 || $payload_exists -eq 0 ]]; then
		
		echo "PROCESSING"
	
	else 
		echo "MISSING"
		exit 0
	
	fi

fi
