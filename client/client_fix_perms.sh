#!/bin/bash

#accepting CL arguemnt but the defualt if no arg is $HOME
directory=${1:-$HOME}
counter=0

#this is interesting
#we change the internal field separator which controls how text is split into words so that it is only a new line, why? 
#so that files with spaces in their names are handled correctly 
OLDIFS=$IFS
IFS=$'\n'

#we loop through the directory while searching for files with perms of 777 
for file in $(find "$directory" -type f -perm 777)
do

#perms=$(stat -c "%a" ${file})
#if [[ $perms -eq 777 ]]
#then
#when we find a file with this criteria we do what is asked of us
chmod 700 "$file"
((counter++))

echo "fixed:${file} 777->700" | tee -a perm_changes.log
#echo "fixed: "${file}"" 777-\>700
#echo "summary: changed=${counter}"
#fi

done
#return the IFS as is so that system settings are not changed
IFS=$OLDIFS
echo "summary: changed=${counter}"
