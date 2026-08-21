#!/bin/bash

# This script updates the package list, upgrades installed packages,
# and removes obsolete packages.

echo "------------------------------------------"
echo "Updating and upgrading system packages..."

# Chain the update, upgrade, autoremove, and autoclean commands for efficiency.
# The -y flag automatically answers "yes" to any prompts.
sudo apt-get update -y && 
sudo apt-get full-upgrade -y && 
sudo apt-get autoremove -y && 
sudo apt-get autoclean -y

echo "------------------------------------------"
echo "System update and cleanup complete."
echo "------------------------------------------"

