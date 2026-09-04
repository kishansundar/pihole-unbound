#!/bin/sh

# Deploys every tracked config file, systemd unit, and helper script in
# this repo to its live location, and enables the timers. Safe to re-run —
# every step is idempotent, and it never restarts unbound.service or
# forces a gravity/roothints run; it only arms schedules and copies files.
#
# Covers what used to require running the same commands by hand:
#   unbound/unbound.conf, unbound/unbound.service, unbound/ulimit.sh
#   unbound/roothints.sh, unbound/roothints.service, unbound/roothints.timer
#   pihole/gravity.service, pihole/gravity.timer

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

deploy_file() {
    src="$1"
    dest="$2"
    owner="$3"
    mode="$4"

    if [ ! -f "${SCRIPT_DIR}/${src}" ]; then
        echo "ERROR: ${SCRIPT_DIR}/${src} not found" >&2
        exit 1
    fi
    sudo cp "${SCRIPT_DIR}/${src}" "$dest" \
        && sudo chown "$owner" "$dest" \
        && sudo chmod "$mode" "$dest" \
        || { echo "ERROR: failed to deploy ${src} to ${dest}" >&2; exit 1; }
    echo "Deployed ${src} -> ${dest}"
}

echo "------------------------------------------"
echo "Deploying unbound.conf..."
if [ -f /etc/unbound/unbound.conf ]; then
    conf_backup="/etc/unbound/unbound.conf.$(date +%Y%m%d_%H%M%S).bak"
    sudo cp -p /etc/unbound/unbound.conf "$conf_backup" \
        && echo "Backed up existing /etc/unbound/unbound.conf to $conf_backup"
fi
deploy_file unbound/unbound.conf /etc/unbound/unbound.conf root:root 644

echo "------------------------------------------"
echo "Deploying unbound.service..."
deploy_file unbound/unbound.service /etc/systemd/system/unbound.service root:root 644

echo "------------------------------------------"
echo "Deploying ulimit.sh..."
deploy_file unbound/ulimit.sh /etc/unbound/ulimit.sh root:root 755

echo "------------------------------------------"
echo "Deploying roothints.sh, roothints.service, roothints.timer..."
deploy_file unbound/roothints.sh /etc/unbound/roothints.sh root:root 755
deploy_file unbound/roothints.service /etc/systemd/system/roothints.service root:root 644
deploy_file unbound/roothints.timer /etc/systemd/system/roothints.timer root:root 644

echo "------------------------------------------"
echo "Deploying gravity.service, gravity.timer..."
deploy_file pihole/gravity.service /etc/systemd/system/gravity.service root:root 644
deploy_file pihole/gravity.timer /etc/systemd/system/gravity.timer root:root 644

echo "------------------------------------------"
echo "Reloading systemd and enabling timers..."
sudo systemctl daemon-reload
sudo systemctl enable --now roothints.timer
sudo systemctl enable --now gravity.timer

echo "------------------------------------------"
echo "unbound.service..."
sudo systemctl enable unbound
if ! systemctl is-active --quiet unbound; then
    echo "Not currently running — starting it now."
    sudo systemctl start unbound
else
    echo "Already running — not restarting automatically, to avoid an"
    echo "unplanned resolution interruption. If unbound.conf or"
    echo "unbound.service just changed, apply it yourself when ready:"
    echo "  sudo systemctl restart unbound"
fi

echo "------------------------------------------"
echo "Done."
echo "------------------------------------------"
