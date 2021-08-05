#!/bin/bash
echo "------------------------------------------"
echo "Systemctl Daemon Reload..."
sudo systemctl daemon-reload
echo "------------------------------------------"
echo "Stopping Pihole..."
sudo systemctl stop pihole-FTL
echo "------------------------------------------"
echo "Removing Logs..."
/usr/local/bin/pihole -f
rm -Rfr /var/log/*
echo "------------------------------------------"
echo "ARP FLUSH...."
/usr/local/bin/pihole arpflush
echo "------------------------------------------"
echo "Deleting Pihole DB..."
rm -Rfr /etc/pihole/pihole-FTL.db
echo "------------------------------------------"
echo "Restarting Unbound..."
sudo systemctl restart unbound
#echo "------------------------------------------"
#echo "Restarting Lighttpd..."
#sudo systemctl restart lighttpd
echo "------------------------------------------"
echo "Restarting Pihole..."
sudo systemctl restart pihole-FTL
echo "------------------------------------------"
echo "Done."
echo "------------------------------------------"
exit
