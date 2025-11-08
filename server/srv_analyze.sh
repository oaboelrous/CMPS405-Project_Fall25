#!/bin/bash


# First get the queue folder which has the .req files, and the results folder to save on it the the results after analyzing the payload


queue_folder=~/queue
results_folder=~/results


# This script should be running all time checking for any new requests, so use while true

while true 
do

	# Look for .req files in queue folder, this can happen by looking for files that end with .req
	for request_file in "$queue_folder"/*.req
	do
	
		# Check if any .req files actually exist (in case glob doesn't match anything)
		[ -f "$request_file" ] || continue
	
		# Because we have to calculate the time for processing 
		start_time=$(date +%s%3N) #To get time in milisconds, first we need to get it in nanaoseoncds and then get the first 3 numbers of it
		
		
		# Get the information from the request file (.req) which was created earlier by srv_access_accept.sh
		req_file="$request_file"
		
		ID=$(grep "^ID=" "$req_file" | cut -d"=" -f2)
		client_user=$(grep "^CLIENT_USER" "$req_file" | cut -d"=" -f2)
		payload_file=$(grep "^PAYLOAD_FILE" "$req_file" | cut -d"=" -f2)
		file_name=$(grep "^FILENAME" "$req_file" | cut -d"=" -f2)
		
		
		
		
		# Now check if the payload file exists in queue folder
		if [ ! -f "$payload_file" ]; then
		
			echo "The Payload file does not exists"
			continue # to skip the loop iteration and go back to the start of the loop and start again			
		fi
		
		
		
		
		# If payload exists
		
		extension=$(echo "$file_name" | awk -F. '{ print $NF }')
		
		if [ "$extension" = "gz" ]; then
			
			# If the file is compressed
			# Use here -c to not delete the file after decompression just to be safe
			num_lines=$(gunzip -c "$payload_file" | wc -l)
			num_words=$(gunzip -c "$payload_file" | wc -w)
			num_bytes=$(gunzip -c "$payload_file" | wc -c)
			
			
		else
		
			# If the file is not compressed 
			
			num_lines=$(wc -l < "$payload_file")
			num_words=$(wc -w < "$payload_file")
			num_bytes=$(wc -c < "$payload_file")
		
		fi
		
		
		
		process_time_UTC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
		
		
		# Write the results for for ~/results/RES_<ID>.txt
		
		res_file=~/results/RES_${ID}.txt
		
		echo "RESULT for ${ID}" > "$res_file"
		echo "CLIENT_USER=${client_user}" >> "$res_file"
		echo "LINES=${num_lines}" >> "$res_file"
		echo "WORDS=${num_words}" >> "$res_file"
		echo "BYTES=${num_bytes}" >> "$res_file"
		echo "PROCESSED_UTC=${process_time_UTC}" >> "$res_file"
		
		
		# End the time 
		end_time=$(date +%s%3N)
		
		# Get the duration
		duration=$((end_time-start_time))
		
		
		# Now append to  ~/logs/worker.log 
		echo "${process_time_UTC} ID=${ID} CLIENT_USER=${client_user} DURATION_MS=${duration} PAYLOAD=${payload_file}" >> ~/logs/worker.log
		
		
		
		# Remove .req and .payload, here used -f to skip any confirmation question
		rm -f "$request_file" "$payload_file"
		
		
		
	done 




done
