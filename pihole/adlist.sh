#!/bin/sh

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
LIST_FILE="${SCRIPT_DIR}/blocklist.txt"
GRAVITY_DB="/etc/pihole/gravity.db"

if [ ! -f "$LIST_FILE" ]; then
    echo "ERROR: $LIST_FILE not found" >&2
    exit 1
fi

create_sql_dump() {
    list_file="$1"
    sql_dump="$2"

    {
        echo 'BEGIN TRANSACTION;'
        echo "DELETE FROM 'adlist_by_group';"
        echo "DELETE FROM 'adlist';"
        echo "-- Reset autoincrement"
        echo "DELETE FROM 'sqlite_sequence' WHERE name='adlist';"
        grep -E '^https?://' "$list_file" \
            | sed 's/[[:space:]]*$//' \
            | sort -u \
            | while IFS= read -r url; do
                  esc=$(printf '%s' "$url" | sed "s/'/''/g")
                  printf "INSERT INTO 'adlist' (address, enabled, comment) VALUES('%s', 1, 'Added by adlist.sh');\n" "$esc"
              done
        echo 'COMMIT;'
    } >"$sql_dump"

    # Check the list actually had at least one usable URL in it
    [ -n "$(grep 'INSERT INTO' "$sql_dump")" ] || return 1
}

TMP_SQL="$(mktemp --tmpdir adlist.XXXXXX.sql)" || exit 1

if ! create_sql_dump "$LIST_FILE" "$TMP_SQL"; then
    echo "ERROR: no valid (http/https) URLs found in $LIST_FILE" >&2
    rm -f "$TMP_SQL"
    exit 1
fi

if ! sqlite3 "$GRAVITY_DB" <"$TMP_SQL"; then
    echo "ERROR: sqlite3 write failed (pihole-FTL holding a lock?)" >&2
    rm -f "$TMP_SQL"
    exit 1
fi
rm -f "$TMP_SQL"
