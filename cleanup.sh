#!/bin/bash

# This script performs maintenance tasks for Pi-hole and other system services.
# It cleans up log files, flushes caches, and restarts services.

echo "------------------------------------------"
echo "Cleaning up log files..."

# Truncate common large log files to zero size instead of deleting them.
# This is safer as it preserves the file with its permissions.
sudo truncate -s 0 /var/log/syslog
sudo truncate -s 0 /var/log/auth.log
sudo truncate -s 0 /var/log/daemon.log
sudo truncate -s 0 /var/log/kern.log

# Remove old, rotated log files (e.g., .log.1, .log.2.gz)
sudo find /var/log -name "*.log.*" -type f -delete
sudo find /var/log -name "*.gz" -type f -delete

echo "Flushing Pi-hole logs..."
/usr/local/bin/pihole -f

echo "------------------------------------------"
echo "Flushing ARP cache for Pi-hole..."
/usr/local/bin/pihole  networkflush

echo "------------------------------------------"
echo "Restarting services..."

# Restart services to apply changes and ensure they are running correctly.
sudo systemctl restart pihole-FTL
sudo systemctl restart unbound

echo "------------------------------------------"
echo "Cleanup complete."
echo "------------------------------------------"
