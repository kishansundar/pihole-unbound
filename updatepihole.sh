
#curl https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts -o /root/scripts/hosts
bash /root/scripts/hblock -O  /root/scripts/hosts
set -e

SRC="/root/scripts/hosts"
OUTPUT="/etc/unbound/ads/ads.conf"


if [ ! -f "$SRC" ]; then
    echo "Could not open $SRC"
    exit 1
fi

awk '/^0\.0\.0\.0/ {
    print "local-zone: \""$2"\" redirect"
    print "local-data: \""$2" A 0.0.0.0\""
}' "$SRC" > "$OUTPUT"

echo "done"

rm -Rfr "$SRC"

/usr/local/bin/pihole -g
