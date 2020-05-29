sqlite3 /etc/pihole/gravity.db "delete from domainlist;" \
&& pihole -w $(cat /root/block/whitelist/white.list) \
&& pihole --regex $(cat /root/block/blackregex/regex.list) \
&& pihole --white-regex $(cat /root/block/whiteregex/regex.list)
