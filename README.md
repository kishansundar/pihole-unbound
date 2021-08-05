#PIHOLE SETUP

```
cp -rf services/unbound.service /etc/systemd/system/unbound.service
cp -rf services/pihole.service /etc/systemd/system/pihole.service
cp -rf services/roothints.service /etc/systemd/system/roothints.service

cp -rf services/pihole.timer /etc/systemd/system/pihole.timer
cp -rf services/roothints.timer /etc/systemd/system/roothints.timer

cp -rf conf/unbound.conf /etc/unbound/unbound.conf
```
