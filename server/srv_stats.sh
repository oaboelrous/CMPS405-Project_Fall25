#!/bin/bash


# Step 1: prepare the worker file
worker_file=~/logs/worker.log


# Get the archive folder for easier use
archive_folder=~/archive


# check if the worker file exists

if [ ! -f "$worker_file" ]; then
	
	echo "logs/worker.log does not exists"
	exit 1
fi

# Step 2: To get the number of jobs just cound the number of lines in the file (because each job on a 1 line)
job_number=$(wc -l < "$worker_file")


# Step 3: Get the durations time
# This will get you all durations form the worker file
durations=$(awk -F'DURATION_MS=' '{print $2}' "$worker_file" | awk '{print $1}')



# Step 4: Sum all durations 
total_durations=0
for duration in $durations; do
	total_durations=$((total_durations + duration))
done



# Step 5: Get the average 
# Avoid dividing by 0
if [ $job_number -gt 0 ]; then 
	average_duration=$((total_durations / job_number))
	
else

	average_duration=0
fi


# Step 6: Get the client users 
# Here first it will get the second part which will be consist of (CLIENT_USER DURATION_MS), then get the first part which is CLIENT_USER
# Then you will have a list separated by space of clients 
client_users=$(awk -F'CLIENT_USER=' '{print $2}' "$worker_file" | awk '{print $1}')



# Step 7: Get the top user (based on how many times each name appears)
# echo: get the users  from the list 
# sort: sort the names alphabetically
# uniq -c: Counts how many times each name appears consecutively (this is why you need to use sort)
# sort -nr: Sort numerically and in reverse orde (the first 1 will be the one with the highest count)
# head -1: get the first row
# awk '{print $2}': Get the second part (the client name)
top_user=$(echo "$client_users" | sort | uniq -c | sort -nr | head -1 | awk '{print $2}')


# If no top user, set to none
if [ -z "$top_user" ]; then 
	top_user="none"
fi


# Step 8: Print the summary
echo "jobs=$job_number avg_time_ms=$average_duration top_user=$top_user"


# Step 9: Move the old logs to archive 
# Search in logs folder for only files type and these files should end with .log and they should be modified more than 7 days ago
old_logs=$(find ~/logs/ -type f -name '*.log' -mtime +7) 



for log_file in $old_logs; do

	gzip "$log_file"
	mv "$log_file.gz" "$archive_folder" # Because gzip will give you worker.log.gz and delete worker.log so to move it you need to add .gz 
					    # So using only "$log_file" will be an error because is does not exists anymore gzip deleted it

done
