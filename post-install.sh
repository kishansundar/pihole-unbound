#! /bin/sh

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
echo "::1 unbound-ipv6" >> /etc/hosts
echo "192.168.1.1 Router.home" >> /etc/hosts

echo "------------------------------------------"
echo "Enabling... Services"
sudo systemctl daemon-reload
sudo systemctl enable --now roothints.timer
sudo systemctl enable --now unbound.service
sudo systemctl enable --now pihole.timer
echo "------------------------------------------"
echo "Done."
echo "------------------------------------------"