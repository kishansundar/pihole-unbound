#!/bin/sh

rm -Rfr ~/unbound-git
git clone https://github.com/NLnetLabs/unbound.git ~/unbound-git
cd ~/unbound-git
git fetch --all
git clean -df
git pull 
git reset --hard origin/master

#./configure --prefix=/usr --sysconfdir=/etc --disable-static --with-pidfile=/etc/unbound/unbound.pid --with-libevent --enable-dnscrypt --enable-dnstap --enable-ecdsa --enable-gost --with-pthreads --disable-systemd --enable-pie --with-libnghttp2

./configure --prefix=/usr --sysconfdir=/etc  --with-libevent --with-ssl --with-pthreads

make && sudo make install

sudo mv -v /usr/sbin/unbound-host /usr/bin/

sudo curl --output /etc/unbound/root.hints https://www.internic.net/domain/named.root

sudo unbound-anchor -a /etc/unbound/root.key -v

unbound-control-setup

rm -Rfr ~/unbound-git