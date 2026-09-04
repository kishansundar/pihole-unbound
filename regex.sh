#!/bin/sh

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
REGEX_FILE="${SCRIPT_DIR}/regex.txt"
GRAVITY_DB="/etc/pihole/gravity.db"

if [ ! -f "$REGEX_FILE" ]; then
    echo "ERROR: $REGEX_FILE not found" >&2
    exit 1
fi

TMP_SQL="$(mktemp --tmpdir regex.XXXXXX.sql)" || exit 1

{
    echo 'BEGIN TRANSACTION;'
    echo "DELETE FROM domainlist WHERE type=3;"
    grep -v '^[[:space:]]*$' "$REGEX_FILE" \
        | sed 's/[[:space:]]*$//' \
        | while IFS= read -r pattern; do
              esc=$(printf '%s' "$pattern" | sed "s/'/''/g")
              printf "INSERT INTO domainlist (type, domain, enabled, comment) VALUES(3, '%s', 1, 'Added by regex.txt');\n" "$esc"
          done
    echo 'COMMIT;'
} >"$TMP_SQL"

if ! grep -q 'INSERT INTO' "$TMP_SQL"; then
    echo "ERROR: no non-blank patterns found in $REGEX_FILE" >&2
    rm -f "$TMP_SQL"
    exit 1
fi

if ! sqlite3 "$GRAVITY_DB" <"$TMP_SQL"; then
    echo "ERROR: sqlite3 write failed (pihole-FTL holding a lock?)" >&2
    rm -f "$TMP_SQL"
    exit 1
fi
rm -f "$TMP_SQL"

# Regex/domainlist changes need a list reload to take effect immediately;
# unlike adlist.sh's gravity/adlist changes, this doesn't need -g/pihole -up.
pihole reloadlists
