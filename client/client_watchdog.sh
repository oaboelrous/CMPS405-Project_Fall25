#!/bin/bash

runs=${1:-2}
#echo $runs

for (( i=1; i<=runs; i++ ));
do
#grab metrics
utc_ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
load=$(awk '{print $1,$2,$3}' /proc/loadavg)
memory=$(free -m | awk '/Mem:/ {print $3"/"$2"MB"}')

echo [$utc_ts] load=$load
echo mem_used = $memory

#this conditional to prvent sleeping on the last iteration
if [ $i -lt $runs ];
then
sleep 60
fi

done

echo "done (loops = ${runs})"
#echo "mem_used=$memory"
#echo $utc_ts
#echo $load