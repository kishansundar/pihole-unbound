#!/bin/sh

sqlite3 /etc/pihole/gravity.db "delete from domainlist;" \
&& sqlite3 /etc/pihole/gravity.db "delete from domainlist_by_group" \
&& sqlite3 /etc/pihole/gravity.db "DELETE FROM 'sqlite_sequence' WHERE name='domainlist'" \
&& pihole -w $(cat /root/block/whitelist/white.list) \
&& pihole --regex $(cat /root/block/regex/regex.list)