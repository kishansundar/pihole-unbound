#!/bin/sh

version=1.13.1

wget https://nlnetlabs.nl/downloads/unbound/unbound-${version}.tar.gz

tar -xzf unbound-${version}.tar.gz && rm -Rfr unbound-${version}.tar.gz
rm -Rfr unbound-stable
mv unbound-${version} unbound-stable
cd ~/unbound-stable

./configure --prefix=/usr --sysconfdir=/etc --disable-static --with-pidfile=/etc/unbound/unbound.pid --with-libevent --enable-dnscrypt --with-pthreads --disable-systemd --enable-pie --with-libnghttp2
 make && sudo make install

 sudo mv -v /usr/sbin/unbound-host /usr/bin/

 sudo curl --output /etc/unbound/root.hints https://www.internic.net/domain/named.cache

 sudo unbound-anchor -a /etc/unbound/root.key -v

 unbound-control-setup
