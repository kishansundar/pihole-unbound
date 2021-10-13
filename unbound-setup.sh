#! /bin/sh

sudo groupadd -g 88 unbound
sudo useradd -c "Unbound DNS resolver" -d /var/lib/unbound -u 88 -g unbound -s /bin/false unbound

sudo apt install libssl-dev libevent-dev libexpat-dev libnghttp2-dev libsodium-dev -y
