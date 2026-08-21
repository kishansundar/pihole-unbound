#!/bin/sh

version=1.26.0

wget https://nlnetlabs.nl/downloads/unbound/unbound-${version}.tar.gz

#https://nlnetlabs.nl/downloads/unbound/unbound-latest.tar.gz

tar -xzf unbound-${version}.tar.gz && rm -Rfr unbound-${version}.tar.gz
rm -Rfr unbound-latest
mv unbound-${version} unbound-latest
cd ~/unbound-latest

#./configure --prefix=/usr --sysconfdir=/etc --disable-static --with-pidfile=/etc/unbound/unbound.pid --with-libevent --enable-dnscrypt --with-pthreads --disable-systemd --enable-pie --with-libnghttp2

#./configure --prefix=/usr --sysconfdir=/etc  --with-libevent --with-ssl --with-pthreads --enable-ecdsa --enable-ed25519 --enable-gost --enable-pie

./configure \
  --prefix=/usr \
  --sysconfdir=/etc \
  --with-conf-file=/etc/unbound/unbound.conf \
  --with-pidfile=/run/unbound.pid \
  --with-username=unbound \
  --with-libevent \
  --with-ssl \
  --with-pthreads \
  --enable-ecdsa \
  --enable-ed25519 \
  --enable-gost \
  --enable-pie \
  --enable-event-api \
  --enable-tfo-client \
  --enable-tfo-server \
  --enable-subnet \
  --enable-cachedb \
  --disable-static \
  --enable-shared

make && sudo make install

sudo mv -v /usr/sbin/unbound-host /usr/bin/

sudo curl --output /etc/unbound/root.hints https://www.internic.net/domain/named.cache

#sudo unbound-anchor -a /etc/unbound/root.key -v

sudo -u unbound unbound-anchor -a /var/lib/unbound/root.key -v || true

unbound-control-setup

rm -Rfr ~/unbound-latest
