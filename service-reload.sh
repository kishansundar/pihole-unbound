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
echo "Done."
echo "------------------------------------------"