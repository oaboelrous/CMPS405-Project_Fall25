#!/bin/bash


# Step 1: Check the input argument and get it 

# First I need to check that the number of arguments equals to 1
# Here $# means the number of arguments 
if [ $# -ne 1 ]; then
	
	echo "Error! enter exactly 1 argument"
	exit 1	

fi

# The first argument after the script name
server="$1"




# Step 2: the paths to save the fiils 

 # Get the current UTC date and time for the metrics file name
 TIMESTAMP=$(date -u +"%Y%m%d_%H%M%S")
 
 # Create the metric file name
 METRIC_FILE="~/tmp/metrics_${TIMESTAMP}.txt"
 
 
 
 
# Step 3: Fill the metric file

# 1- hostname and UTC time
hostname=$(hostname)
UTC_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")


# 2- get the load average (how busy the system is / how many processes are waiting for the cpu)

# uptime will give you the load average and other extra information, we need only the load average which is the last part
# after running uptime use awk (text tool) with the -F argument (split by filed which is specified by "load average:") then use print $2 (to print the second part) 
load_avg=$(uptime | awk -F'load average:' '{ print $2 }')


# 3- free will give you the memory usage in 2 rows, first row --> Mem: (which we need and use grep to get it) and will also give you 6 columns (we need the second column which is the used) so use awk and get the second part
memory_usage=$(free | grep Mem: | awk '{ print $3 }')


# 4- To get processes use ps and specify to get only the (pid and cmd which is the name of the proccess) and then run the command head (by default will give you the first 10 lines) use -n 6 to get the first 5 and the header  
top_processes=$(ps -eo pid,cmd --sort=-%cpu | head -n 6)


# Step 4: Print the vaules from the top vaiables and store them in the metric file


{

	echo "Hostname: $hostname"
	echo "UTC time: $UTC_time"
	echo "Load average: $load_avg"
	echo "Memory usage: $memory_usage"
	echo "Top 5 processes:"
	echo "$top_processes" # used here "" to keep the line breaks

} > "$METRIC_FILE"


# Step 5: Copy the file to the server in a secure way

scp "$METRIC_FILE" "$server:~/results/"


# Step 6: Print confirmation
# $? will reuturn the exit code of the last command, if 0 --> means success, else error
# I used the command basename just to get the file name from the full path to match the sample output
if [ $? -eq 0 ]; then
	echo "PUSHED ~/results/$(basename "$METRIC_FILE")"
else 

	echo "Failed to copy the metric file to the server"

fi
