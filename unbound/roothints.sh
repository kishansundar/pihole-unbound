#!/bin/sh

# Same safe-refresh pattern used in unbound-latest.sh: fetch to a temp file
# first and only replace the live root.hints if the download actually
# succeeded and looks like a real hints file. The old roothints.service
# ran `curl -o /etc/unbound/root.hints ...` directly — a failed/truncated
# fetch would have clobbered the file in place, and unbound.conf has no
# forward-zone fallback, so root.hints is the only path to resolution.
#
# -4: this host's IPv6 route to internic.net is blackholed (TLS handshake
# hangs and times out over IPv6, confirmed with curl -6; IPv4 works fine
# in <1s) — curl tries IPv6 first by default, and depending on timing that
# either falls back to IPv4 cleanly or surfaces as a bare connection
# reset. Forcing IPv4 here skips the broken path entirely rather than
# relying on the temp-file safety net to catch the failure after the fact.

root_hints_tmp=$(mktemp)
if curl -4 -fsS --output "$root_hints_tmp" https://www.internic.net/domain/named.cache \
    && [ -s "$root_hints_tmp" ] \
    && [ "$(wc -l < "$root_hints_tmp")" -ge 10 ]; then
  mv "$root_hints_tmp" /etc/unbound/root.hints
  chown unbound:unbound /etc/unbound/root.hints
  echo "OK: root.hints refreshed ($(wc -l < /etc/unbound/root.hints) lines)."
else
  echo "WARN: root.hints refresh failed or looked invalid — keeping the existing /etc/unbound/root.hints untouched." >&2
  rm -f "$root_hints_tmp"
  exit 1
fi
