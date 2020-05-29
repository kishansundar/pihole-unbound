sqlite3 /etc/pihole/gravity.db "delete from domainlist;" \
&& pihole -w $(cat whitelist/white.list) \
&& pihole --regex $(cat blackregex/regex.list) \
&& pihole --white-regex $(cat whiteregex/regex.list)
