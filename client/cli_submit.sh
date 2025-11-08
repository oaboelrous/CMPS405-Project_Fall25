#!/bin/bash


# Step 1 Check arguments
if [ $# -ne 4 ]; then
  echo "You should include 4 arguments"
  exit 1
fi


# Step 2: Read arguments

server_host=$1      
input_file=$2       
access_code=$3      
client_user=$4      


# Step 3: Compress the input file, using -c will not put the result in the new file. So create one with the same name
gz_file="${input_file}.gz"
gzip -c "$input_file" > "$gz_file"


# Step 4: permissions
chmod u=rw,g=rw,o=r "$gz_file"
echo "Permissions set on $gz_file"

# Step 5: Extract basename

file_name=$(basename "$gz_file")  


# Step 6: Run the server script using SSH
file_name=$(basename "$gz_file")  
remote_script="/home/yazan-server-vm/srv_access_accept.sh"

# using variables such as: client_user='$client_user' to assign these variables on the server side and can use them later (on the server side)
# bash to run the script (srv_access_accept.sh) on the server side
# Using "" means this will run on the server side 
response=$(ssh "$server_host" 
  "client_user='$client_user' access_code='$access_code' fname='$file_name' bash '$remote_script'")


# -----------------------
# Step 7: Check server response
# -----------------------
echo "Server response: $response"

if [[ "$response" == ACCEPT* ]]; then
    # Extract the REQ_ID
    REQ_ID=$(echo "$response" | awk '{print $2}')
    echo "Accepted with ID: $REQ_ID"
else
    echo "Rejected by server. Response: $response"
    exit 1
fi


# Step 8: Upload payload

scp "$gz_file" "$server_host:~/queue/${REQ_ID}.payload"