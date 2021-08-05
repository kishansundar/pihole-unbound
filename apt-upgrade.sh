#!/bin/bash
echo "------------------------------------------"
echo "APT UPDATE..."
sudo apt-get update -y
echo "------------------------------------------"
echo "APT FULL_UPGRADE..."
sudo apt full-upgrade -y
echo "------------------------------------------"
echo "Done."
echo "------------------------------------------"

exit
