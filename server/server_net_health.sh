#!/bin/bash

#we take the CL argument and set the initial values 
host=$1
ping_status="FAIL"
port22="CLOSED"

#a loop to make the user enter a hostname if forgotten
while [ -z "$host" ] 
do
read -p "Enter a hostname: " host
done

#the ping workflow
#we ping the host (while hiding all the output for a cleaner terminal)
#then take the exit code to determine if successful and change the status based on it
ping -c 1 -W 3 "$host" >/dev/null 2>&1
ping_ok=$?
if [ "$ping_ok" -eq 0 ]
then 
ping_status="OK"
fi


#tring manipulation using awk to extract the ip address from the ping output
#why? because netcat doesn't want to work with hostnames for some reason
#F = field separator, and separate by parenthese on the line that has PING
host_ip=$(ping -c1 "$host" 2>/dev/null | awk -F'[()]' '/PING/{print $2}')

#same workflow as ping
nc -z "$host_ip" 22
ssh_open=$?
if [ "$ssh_open" -eq 0 ]
then 
port22="OPEN"
fi

echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ"), target=${host}, ping=${ping_status}, SSH_Port=${port22}" | tee -a ~/logs/health.log
