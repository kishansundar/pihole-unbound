#!/bin/bash

echo "Stopping Pihole..."
sudo systemctl stop pihole-FTL
echo "Deleting Pihole DB..."
rm -Rfr /etc/pihole/pihole-FTL.db
echo "Removing Logs..."
/usr/local/bin/pihole -f
rm -Rfr /var/log/*
echo "Restarting Unbound..."
sudo systemctl restart unbound
#echo "Restarting Stubby..."
#sudo systemctl restart stubby
echo "ARP FLUSH...."
/usr/local/bin/pihole arpflush

echo "Restarting Pihole..."
sudo systemctl restart pihole-FTL

echo "Done."

exit
