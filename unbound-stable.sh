#!/bin/sh

version=1.13.1

wget https://nlnetlabs.nl/downloads/unbound/unbound-${version}.tar.gz

#https://nlnetlabs.nl/downloads/unbound/unbound-latest.tar.gz

tar -xzf unbound-${version}.tar.gz && rm -Rfr unbound-${version}.tar.gz
rm -Rfr unbound-latest
mv unbound-${version} unbound-latest
cd ~/unbound-latest

./configure --prefix=/usr --sysconfdir=/etc --disable-static --with-pidfile=/etc/unbound/unbound.pid --with-libevent --enable-dnscrypt --with-pthreads --disable-systemd --enable-pie --with-libnghttp2
 make && sudo make install

 sudo mv -v /usr/sbin/unbound-host /usr/bin/

 sudo curl --output /etc/unbound/root.hints https://www.internic.net/domain/named.cache

 sudo unbound-anchor -a /etc/unbound/root.key -v

 unbound-control-setup

 rm -Rfr ~/unbound-latest