# PIHOLE

## Pihole Setup

`./apt-upgrade.sh`
`./pihole-setup.sh`
`./unbound-setup.sh`
`./unbound-update.sh`
`./service-update.sh`
`./post-install.sh`
`./cleanup.sh`
`./adlist.sh`
`./pihole-update.sh`

## Unbound Setup

```
wget https://nlnetlabs.nl/downloads/unbound/unbound-1.13.1.tar.gz

tar -xzf unbound-1.13.1.tar.gz && rm -Rfr unbound-1.13.1.tar.gz
mv unbound-1.13.1 unbound
./unbound.sh
```

## Lightttpd Settings

```
mkdir /etc/lighttpd/certs
openssl req -x509 -nodes -days 7300 -newkey rsa:2048 -sha256 -keyout /etc/lighttpd/certs/server.pem -out /etc/lighttpd/certs/server.pem
chmod 600 /etc/lighttpd/certs/server.pem

Modify /etc/lighttpd/lighttpd.conf adding the following lines to enable https:

$SERVER["socket"] == ":443" {
ssl.engine = "enable"
ssl.pemfile = "/etc/lighttpd/certs/server.pem"
}

please add "mod_openssl" to server.modules list in lighttpd.conf

sudo systemctl restart lighttpd

```

## Update Services

`cp -rf services/unbound.service /etc/systemd/system/unbound.service && cp -rf services/pihole.service /etc/systemd/system/pihole.service && cp -rf services/roothints.service /etc/systemd/system/roothints.service && cp -rf services/pihole.timer /etc/systemd/system/pihole.timer && cp -rf services/roothints.timer /etc/systemd/system/roothints.timer && cp -rf conf/unbound.conf /etc/unbound/unbound.conf`
