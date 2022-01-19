#! /bin/sh
echo "------------------------------------------"
echo "Pihole... Status"
sudo systemctl status pihole-FTL
echo "------------------------------------------"
echo "Unbound... Status"
sudo systemctl status unbound
echo "------------------------------------------"
echo "PiholeTimer... Status"
sudo systemctl status pihole.timer
echo "------------------------------------------"
echo "RootHints... Status"
sudo systemctl status roothints.timer
echo "------------------------------------------"
echo "Cleanup... Status"
sudo systemctl status cleanup.timer
echo "------------------------------------------"
