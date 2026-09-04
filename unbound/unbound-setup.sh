#! /bin/sh

# uid/gid matches this host's actual provisioned unbound account (8888),
# not the Unbound project's suggested 88 — verified against `id unbound`.
UNBOUND_UID=8888
UNBOUND_GID=8888

if ! getent group unbound >/dev/null; then
  sudo groupadd -g "$UNBOUND_GID" unbound
else
  echo "Group 'unbound' already exists, skipping."
fi

if ! id unbound >/dev/null 2>&1; then
  sudo useradd -c "Unbound DNS resolver" -d /var/lib/unbound -m \
    -u "$UNBOUND_UID" -g unbound -s /bin/false unbound
else
  echo "User 'unbound' already exists, skipping."
  # useradd -m only creates the home directory at account-creation time;
  # make sure it exists even when the account already did.
  sudo mkdir -p /var/lib/unbound
  sudo chown unbound:unbound /var/lib/unbound
  sudo chmod 750 /var/lib/unbound
fi

# Only libssl-dev and libevent-dev are actually referenced by
# unbound-latest.sh's active ./configure flags (--with-ssl,
# --with-libevent). Previously also installed libexpat-dev (not a real
# package on this Debian release — it's libexpat1-dev — and unused
# either way), libnghttp2-dev, libsodium-dev, libprotobuf-c-dev, and
# protobuf-c-compiler, all leftovers from configure variants that were
# never actually used (dnscrypt/dnstap/HTTP2 support).
sudo apt install -y libssl-dev libevent-dev
