#! /bin/sh

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

cp -rf ${SCRIPT_DIR:?}/services/unbound.service /etc/systemd/system/unbound.service
cp -rf ${SCRIPT_DIR:?}/services/pihole.service /etc/systemd/system/pihole.service
cp -rf ${SCRIPT_DIR:?}/services/roothints.service /etc/systemd/system/roothints.service

cp -rf ${SCRIPT_DIR:?}/services/pihole.timer /etc/systemd/system/pihole.timer
cp -rf ${SCRIPT_DIR:?}/services/roothints.timer /etc/systemd/system/roothints.timer

cp -rf ${SCRIPT_DIR:?}/conf/unbound.conf /etc/unbound/unbound.conf


echo "ANALYZE_ONLY_A_AND_AAAA=true" >> /etc/pihole/pihole-FTL.conf
echo "MAXDBDAYS=1" >> /etc/pihole/pihole-FTL.conf

sed -i -e 's/cache-size=10000/cache-size=0/g' /etc/dnsmasq.d/01-pihole.conf
echo "proxy-dnssec" > /etc/dnsmasq.d/03-pihole-extra.conf
echo "read-ethers" >> /etc/dnsmasq.d/03-pihole-extra.conf


echo "127.0.1.2 unbound-ipv4" >> /etc/hosts
echo "::1 unbound-ipv6" >> /etc/hosts
echo "192.168.1.1 Router.home" >> /etc/hosts

#### Enable Services
sudo systemctl daemon-reload
sudo systemctl enable --now roothints.timer
sudo systemctl enable --now unbound.service
sudo systemctl enable --now pihole.timer