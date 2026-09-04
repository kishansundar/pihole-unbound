#! /bin/sh

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

echo "------------------------------------------"
echo "Copying... *.service"
cp -rf ${SCRIPT_DIR:?}/services/unbound.service /etc/systemd/system/unbound.service
cp -rf ${SCRIPT_DIR:?}/services/pihole.service /etc/systemd/system/pihole.service
cp -rf ${SCRIPT_DIR:?}/services/roothints.service /etc/systemd/system/roothints.service
cp -rf ${SCRIPT_DIR:?}/services/cleanup.service /etc/systemd/system/cleanup.service

echo "------------------------------------------"
echo "Copying... *.timer"
cp -rf ${SCRIPT_DIR:?}/services/pihole.timer /etc/systemd/system/pihole.timer
cp -rf ${SCRIPT_DIR:?}/services/roothints.timer /etc/systemd/system/roothints.timer
cp -rf ${SCRIPT_DIR:?}/services/cleanup.timer /etc/systemd/system/cleanup.timer

echo "------------------------------------------"
echo "Copying... unbound.conf"
cp -rf ${SCRIPT_DIR:?}/conf/unbound.conf /etc/unbound/unbound.conf

echo "------------------------------------------"
echo "User Access... Unbound"
chown -R unbound:unbound /etc/unbound

echo "------------------------------------------"
echo "Updating... piholeconfig"
echo "ANALYZE_ONLY_A_AND_AAAA=true" >> /etc/pihole/pihole-FTL.conf
echo "MAXDBDAYS=1" >> /etc/pihole/pihole-FTL.conf

echo "------------------------------------------"
echo "Updating... dnsmasq"
sed -i -e 's/cache-size=10000/cache-size=0/g' /etc/dnsmasq.d/01-pihole.conf
echo "proxy-dnssec" > /etc/dnsmasq.d/03-pihole-extra.conf
echo "read-ethers" >> /etc/dnsmasq.d/03-pihole-extra.conf

echo "------------------------------------------"
echo "Updating... Hosts"
echo "127.0.1.2 unbound-ipv4" >> /etc/hosts
# ::1 localhost ip6-localhost ip6-loopback
sed -i -e 's/::1 localhost ip6-localhost ip6-loopback/::1 unbound-ipv6 localhost ip6-localhost ip6-loopback/g'
sed -i -e 's/127.0.0.1 localhost/127.0.0.1 Dietpi localhost/g'
echo "192.168.1.1 Router" >> /etc/hosts
echo "192.168.1.2 Orbi" >> /etc/hosts

echo "------------------------------------------"
echo "Enabling... Services"
sudo systemctl daemon-reload
sudo systemctl enable --now roothints.timer
sudo systemctl enable --now unbound.service
sudo systemctl enable --now pihole.timer

echo "------------------------------------------"
echo "Cleaningup... Folders"
rm -Rfr ~/unbound
rm -Rfr ~/Pi-hole

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
