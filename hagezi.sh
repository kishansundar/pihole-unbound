#!/bin/sh
set -u

LIST_URL="https://gitlab.com/kishansundar/pihole-adlist/-/raw/main/basic"
GRAVITY_DB="/etc/pihole/gravity.db"

pick_url() {
    printf '%s' "$1" | tr '|' '\n' | while IFS= read -r cand; do
        [ -z "$cand" ] && continue
        code=$(curl -sS -o /dev/null -w '%{http_code}' \
                    --max-time 20 --location --range 0-0 "$cand" 2>/dev/null)
        case "$code" in
            200|206) printf '%s\n' "$cand"; break ;;
        esac
    done | head -n 1
}

create_sql_dump() {
    list_url="$1"
    sql_dump="$2"
    tmp_list="${sql_dump}.raw"

    curl --silent --show-error --fail --location --max-time 60 \
         --output "$tmp_list" "$list_url" || { rm -f "$tmp_list"; return 1; }

    wanted=$(tr -d '\r' <"$tmp_list" | grep -cE '^https?://')

    {
        echo 'BEGIN TRANSACTION;'
        echo 'DELETE FROM adlist_by_group;'
        echo 'DELETE FROM adlist;'
        echo '-- reset autoincrement'
        echo "DELETE FROM sqlite_sequence WHERE name='adlist';"
        tr -d '\r' < "$tmp_list" \
            | sed 's/[[:space:]]*$//' \
            | grep -E '^https?://' \
            | sort -u \
            | while IFS= read -r line; do
                  url=$(pick_url "$line")
                  if [ -z "$url" ]; then
                      echo "WARN: no reachable source for ${line%%|*}" >&2
                      continue
                  fi
                  esc=$(printf '%s' "$url" | sed "s/'/''/g")
                  printf "INSERT INTO adlist (address, enabled, comment) VALUES('%s', 1, 'Added by adlist.sh');\n" "$esc"
              done
        echo 'COMMIT;'
    } >"$sql_dump"

    rm -f "$tmp_list"
    got=$(grep -c 'INSERT INTO' "$sql_dump")
    echo "Resolved $got of $wanted lists"
    [ "$got" -gt 0 ]
}

TMP_SQL="$(mktemp --tmpdir adlist.XXXXXX.sql)" || exit 1

if ! create_sql_dump "$LIST_URL" "$TMP_SQL"; then
    echo "ERROR: unable to fetch or parse adlist" >&2
    rm -f "$TMP_SQL"
    exit 1
fi

if ! sqlite3 "$GRAVITY_DB" <"$TMP_SQL"; then
    echo "ERROR: sqlite3 write failed (pihole-FTL holding a lock?)" >&2
    rm -f "$TMP_SQL"
    exit 1
fi
rm -f "$TMP_SQL"

pihole -g
