#!/bin/sh

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

version="${UNBOUND_VERSION:-1.26.0}"

# --- (3) check whether a newer release exists upstream (best-effort, non-fatal) ---
latest_seen=$(curl -fsS https://nlnetlabs.nl/downloads/unbound/ 2>/dev/null \
  | grep -oE 'unbound-[0-9]+\.[0-9]+\.[0-9]+\.tar\.gz"' \
  | sed -E 's/unbound-([0-9.]+)\.tar\.gz"/\1/' \
  | sort -V | tail -n1)
if [ -n "$latest_seen" ] && [ "$latest_seen" != "$version" ]; then
  echo "NOTE: building pinned version ${version}, but ${latest_seen} is available upstream." >&2
  echo "      override with: UNBOUND_VERSION=${latest_seen} ./unbound-latest.sh" >&2
fi

cd ~ || exit 1

wget -O "unbound-${version}.tar.gz" "https://nlnetlabs.nl/downloads/unbound/unbound-${version}.tar.gz" \
  || { echo "ERROR: download of unbound-${version}.tar.gz failed" >&2; exit 1; }

#https://nlnetlabs.nl/downloads/unbound/unbound-latest.tar.gz

# --- (2) verify the tarball against NLnet Labs' release signing key before doing anything else ---
# Key: "NLnet Labs releases signing key G2" (in effect for tarballs published since 2026-01-01)
# Fingerprint: 2310 1869 0C4D 903E F419 146A A144 323D EAAC DF45
# https://nlnetlabs.nl/signing-keys/
NLNETLABS_FPR="231018690C4D903EF419146AA144323DEAACDF45"

wget -O "unbound-${version}.tar.gz.asc" "https://nlnetlabs.nl/downloads/unbound/unbound-${version}.tar.gz.asc" \
  || { echo "ERROR: download of the .asc signature failed" >&2; exit 1; }
wget -O nlnetlabs.asc "https://nlnetlabs.nl/downloads/keys/releases-g2.asc" \
  || { echo "ERROR: download of NLnet Labs' signing key failed" >&2; exit 1; }

# gpgv (unlike full gpg) requires a binary keyring — the downloaded key is
# ASCII-armored, so it has to be dearmored first or gpgv fails with
# "invalid packet" trying to parse the "-----BEGIN PGP..." text as binary.
gpg --dearmor -o nlnetlabs.certs nlnetlabs.asc \
  || { echo "ERROR: could not process NLnet Labs' signing key" >&2; exit 1; }

got_fpr=$(gpg --with-colons --import-options show-only --import --fingerprint nlnetlabs.certs 2>/dev/null \
  | awk -F: '/^fpr:/{print $10; exit}')
if [ "$got_fpr" != "$NLNETLABS_FPR" ]; then
  echo "ERROR: downloaded signing key fingerprint does not match the pinned NLnet Labs fingerprint." >&2
  echo "       expected: $NLNETLABS_FPR" >&2
  echo "       got:      ${got_fpr:-<none>}" >&2
  exit 1
fi

gpgv --keyring=./nlnetlabs.certs "unbound-${version}.tar.gz.asc" "unbound-${version}.tar.gz" \
  || { echo "ERROR: signature verification failed for unbound-${version}.tar.gz — refusing to build" >&2; exit 1; }
echo "OK: unbound-${version}.tar.gz signature verified against NLnet Labs' release key."

tar -xzf "unbound-${version}.tar.gz" || { echo "ERROR: extraction failed" >&2; exit 1; }
rm -f "unbound-${version}.tar.gz" "unbound-${version}.tar.gz.asc" nlnetlabs.asc nlnetlabs.certs
rm -Rf unbound-latest
mv "unbound-${version}" unbound-latest
cd unbound-latest || exit 1

#./configure --prefix=/usr --sysconfdir=/etc --disable-static --with-pidfile=/etc/unbound/unbound.pid --with-libevent --enable-dnscrypt --with-pthreads --disable-systemd --enable-pie --with-libnghttp2

#./configure --prefix=/usr --sysconfdir=/etc  --with-libevent --with-ssl --with-pthreads --enable-ecdsa --enable-ed25519 --enable-gost --enable-pie

./configure \
  --prefix=/usr \
  --sysconfdir=/etc \
  --with-conf-file=/etc/unbound/unbound.conf \
  --with-pidfile=/run/unbound.pid \
  --with-username=unbound \
  --with-libevent \
  --with-ssl \
  --with-pthreads \
  --enable-ecdsa \
  --enable-ed25519 \
  --enable-gost \
  --enable-pie \
  --enable-event-api \
  --enable-tfo-client \
  --enable-tfo-server \
  --enable-subnet \
  --enable-cachedb \
  --disable-static \
  --enable-shared \
  || { echo "ERROR: configure failed" >&2; exit 1; }

make || { echo "ERROR: build failed" >&2; exit 1; }
sudo make install || { echo "ERROR: make install failed" >&2; exit 1; }

sudo mv -v /usr/sbin/unbound-host /usr/bin/

# --- deploy this repo's tracked unbound.conf / unbound.service / ulimit.sh ---
for f in unbound.conf unbound.service ulimit.sh; do
  [ -f "${SCRIPT_DIR}/${f}" ] || { echo "ERROR: ${SCRIPT_DIR}/${f} not found — can't deploy" >&2; exit 1; }
done

if [ -f /etc/unbound/unbound.conf ]; then
  conf_backup="/etc/unbound/unbound.conf.$(date +%Y%m%d_%H%M%S).bak"
  sudo cp -p /etc/unbound/unbound.conf "$conf_backup" \
    && echo "Backed up existing /etc/unbound/unbound.conf to $conf_backup"
fi

sudo cp "${SCRIPT_DIR}/unbound.conf" /etc/unbound/unbound.conf \
  && sudo chown root:root /etc/unbound/unbound.conf \
  && sudo chmod 644 /etc/unbound/unbound.conf \
  || { echo "ERROR: failed to deploy unbound.conf" >&2; exit 1; }

sudo cp "${SCRIPT_DIR}/unbound.service" /etc/systemd/system/unbound.service \
  && sudo chmod 644 /etc/systemd/system/unbound.service \
  || { echo "ERROR: failed to deploy unbound.service" >&2; exit 1; }

sudo cp "${SCRIPT_DIR}/ulimit.sh" /etc/unbound/ulimit.sh \
  && sudo chown root:root /etc/unbound/ulimit.sh \
  && sudo chmod 755 /etc/unbound/ulimit.sh \
  || { echo "ERROR: failed to deploy ulimit.sh" >&2; exit 1; }

sudo systemctl daemon-reload

# Fetch to a temp file first and only replace the live root.hints if the
# download actually succeeded and looks like a real hints file — a failed
# or truncated overwrite here matters a lot now that unbound.conf has no
# forward-zone fallback: root.hints is the only path left to resolution.
root_hints_tmp=$(mktemp)
if curl -fsS --output "$root_hints_tmp" https://www.internic.net/domain/named.cache \
    && [ -s "$root_hints_tmp" ] \
    && [ "$(wc -l < "$root_hints_tmp")" -ge 10 ]; then
  sudo mv "$root_hints_tmp" /etc/unbound/root.hints
  sudo chown unbound:unbound /etc/unbound/root.hints
  echo "OK: root.hints refreshed ($(wc -l < /etc/unbound/root.hints) lines)."
else
  echo "WARN: root.hints refresh failed or looked invalid — keeping the existing /etc/unbound/root.hints untouched." >&2
  rm -f "$root_hints_tmp"
fi

# --- (1) + (5) trust anchor: correct path, ensure the directory exists, match unbound.service's own pattern ---
sudo mkdir -p /etc/unbound/anchor
sudo unbound-anchor -a /etc/unbound/anchor/root.key -v \
  || echo "NOTE: unbound-anchor exited non-zero — this can be expected (e.g. anchor already current). Verify /etc/unbound/anchor/root.key manually if unsure." >&2
sudo chown unbound:unbound /etc/unbound/anchor/root.key

unbound-control-setup

cd ~ || exit 1
rm -Rf unbound-latest

# --- (4) the installed binary only takes effect once the running process is restarted ---
echo "Restarting unbound.service to pick up the new binary..."
sudo systemctl restart unbound
sudo systemctl --no-pager status unbound
