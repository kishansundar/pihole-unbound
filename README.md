# PIHOLE

## Script Setup

```
./apt-upgrade.sh
./pihole-setup.sh
./unbound-setup.sh
./unbound-git.sh
./unbound-stable.sh
./service-update.sh
./post-install.sh
./cleanup.sh
./adlist.sh
./pihole-update.sh
./service-reload.sh
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
