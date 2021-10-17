#!/bin/bash

sudo apt install git build-essential wget -y 

git clone --depth 1 https://github.com/pi-hole/pi-hole.git ~/Pi-hole
cd ~/Pi-hole/automated\ install/
sudo bash basic-install.sh
