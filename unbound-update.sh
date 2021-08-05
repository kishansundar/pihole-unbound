#! /bin/sh

cd ~/unbound
git fetch --all
git clean -df
git pull 
git reset --hard origin/master

./configure --prefix=/usr --sysconfdir=/etc --disable-static --with-pidfile=/etc/unbound/unbound.pid --with-libevent --enable-dnscrypt --with-pthreads --disable-systemd --enable-pie --with-libnghttp2
 make && sudo make install

 sudo mv -v /usr/sbin/unbound-host /usr/bin/

 sudo curl --output /etc/unbound/root.hints https://www.internic.net/domain/named.cache

 sudo unbound-anchor -a /etc/unbound/root.key -v

 unbound-control-setup