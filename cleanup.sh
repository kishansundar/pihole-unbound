#!/bin/bash

echo "Stopping Pihole..."
sudo systemctl stop pihole-FTL
echo "Deleting Pihole DB..."
rm -Rfr /etc/pihole/pihole-FTL.db
echo "Removing Logs..."
rm -Rfr /var/log/*
echo "Restarting Unbound..."
sudo systemctl restart unbound
#echo "Restarting Stubby..."
#sudo systemctl restart stubby

echo "Restarting Pihole..."
sudo systemctl restart pihole-FTL

echo "Done."

exit
