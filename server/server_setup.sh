#!/bin/bash

sudo apt update

#make required dirs
mkdir -p ~/queue ~/tokens ~/results ~/logs ~/archive

#make allowlist
touch ~/tokens/allowlist.txt

#make all scripts execuatble
chmod +x ~/Desktop/CMPS405-Project_Fall25/server/*.sh

#MySQL setup
sudo apt install mysql-server -y 
sudo systemctl enable mysql 
sudo systemctl status mysql
