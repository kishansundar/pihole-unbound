#!/bin/bash

echo "APT UPDATE..."
sudo apt-get update -y
#echo "APT UPGRADE..."
#sudo apt-get upgrade -y
#echo "APT DIST-UPGRADE..."
#sudo apt-get dist-upgrade -y
echo "APT FULL_UPGRADE..."
sudo apt full-upgrade -y

echo "Done."

exit
