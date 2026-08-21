#!/bin/sh

# This script updates and reloads systemd services and configurations.

# Exit immediately if a command exits with a non-zero status.
set -e

# Get the directory of the script
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

echo "------------------------------------------"
echo "Updating systemd service files and configurations..."
echo "------------------------------------------"

echo "Copying... *.service"
sudo cp -rf "${SCRIPT_DIR}/services/unbound.service" /etc/systemd/system/unbound.service
sudo cp -rf "${SCRIPT_DIR}/services/pihole.service" /etc/systemd/system/pihole.service
sudo cp -rf "${SCRIPT_DIR}/services/roothints.service" /etc/systemd/system/roothints.service
sudo cp -rf "${SCRIPT_DIR}/services/cleanup.service" /etc/systemd/system/cleanup.service

echo "------------------------------------------"
echo "Copying... *.timer"
sudo cp -rf "${SCRIPT_DIR}/services/pihole.timer" /etc/systemd/system/pihole.timer
sudo cp -rf "${SCRIPT_DIR}/services/roothints.timer" /etc/systemd/system/roothints.timer
sudo cp -rf "${SCRIPT_DIR}/services/cleanup.timer" /etc/systemd/system/cleanup.timer

echo "------------------------------------------"
echo "Copying... unbound.conf"
sudo cp -rf "${SCRIPT_DIR}/conf/unbound.conf" /etc/unbound/unbound.conf

echo "------------------------------------------"
echo "Reloading systemd daemon and restarting services..."
echo "------------------------------------------"

echo "Daemon Reload..."
sudo systemctl daemon-reload

echo "------------------------------------------"
echo "Restarting Unbound..."
sudo systemctl restart unbound

echo "------------------------------------------"
echo "Restarting Pihole Timer..."
sudo systemctl restart pihole.timer

echo "------------------------------------------"
echo "Restarting Roothints Timer..."
sudo systemctl restart roothints.timer

echo "------------------------------------------"
echo "Restarting cleanup Timer..."
sudo systemctl restart cleanup.timer

echo "------------------------------------------"
echo "Done."
echo "------------------------------------------"
