# Pi-hole + Unbound

Shell scripts that provision and maintain a self-hosted, network-wide DNS
ad-blocker: **Pi-hole** answers every DNS query on the LAN and sinkholes
ad/tracker domains, backed by **Unbound**, a validating recursive resolver
compiled from source on the same box, which forwards everything else to
Quad9 over DNS-over-TLS. Built for a Raspberry Pi running DietPi; the
scripts are plain `apt`/`systemd`-based Debian shell and should work on any
Debian-derived host.

There is no installer or Makefile — each script below is run by hand, as
root, in the order listed.

## How it works

```mermaid
flowchart LR
    client["LAN client"] -->|"UDP/TCP :53"| ftl["Pi-hole FTL\n(dnsmasq core)"]
    ftl -->|"domain in gravity.db?"| decision{"blocked?"}
    decision -->|yes| sink["sinkhole reply\nNXDOMAIN / 0.0.0.0"]
    decision -->|"no, cache miss"| unbound["Unbound\n127.0.0.1:5353\n(loopback only)"]
    unbound -->|"DNS-over-TLS :853"| quad9["Quad9\n9.9.9.9 / 149.112.112.112"]
    unbound -.->|"root.hints, monthly"| hints["roothints.timer"]
    blocklist["blocklist.txt"] --> loader["adlist.sh"]
    loader -->|"sqlite3 INSERT"| gdb[("gravity.db")]
    gdb -.->|"pihole -g compiles\n(manual only)"| ftl
    regexfile["regex.txt"] --> regexsh["regex.sh"]
    regexsh -->|"sqlite3 INSERT\n+ pihole reloadlists"| gdb
    admin["lighttpd admin UI\n:80 / :443"] -.manages.-> ftl
```

Pi-hole (FTL) is the DNS server every device on the LAN talks to. It checks
each query against `/etc/pihole/gravity.db` and sinkholes matches; anything
else goes to Unbound, which only listens on loopback (`127.0.0.1:5353`) and
forwards upstream over DNS-over-TLS to Quad9. Blocklists and regex rules
are not managed through Pi-hole's own UI — `adlist.sh` reads URLs from the
local `blocklist.txt` and writes them into `gravity.db`'s `adlist` table;
`regex.sh` reads patterns from the local `regex.txt` and writes them into
`gravity.db`'s `domainlist` table (type `3`, deny/regex), then runs
`pihole reloadlists`. Both used to depend on an external GitLab repo
([kishansundar/pihole-adlist](https://gitlab.com/kishansundar/pihole-adlist))
— that repo is gone now; the source lists live in this repo instead.

Pi-hole's upstream DNS server has to be pointed at `127.0.0.1#5353` for this
to work — that's set interactively during `pihole-setup.sh`'s call into
Pi-hole's own installer (or by hand in the admin UI). Nothing here verifies
it automatically.

## Prerequisites

- Debian-based host (developed against DietPi on a Raspberry Pi), run as
  `root`.
- A host that already has the systemd units enabled and running (see
  **State of this repo** below) — `unbound.conf`/`unbound.service` are
  tracked in this repo again, but nothing here deploys them to `/etc` or
  reloads systemd.
- Internet access for `apt`, GitHub, and `nlnetlabs.nl`. No longer needs
  GitLab — `adlist.sh`/`regex.sh` read local files now.

## Install order

```
./apt-upgrade.sh
./pihole-setup.sh
./unbound-setup.sh
./unbound-latest.sh
./adlist.sh
./pihole-update.sh
```

1. **`apt-upgrade.sh`** — `apt-get update && full-upgrade && autoremove && autoclean`.
2. **`pihole-setup.sh`** — installs `git build-essential wget`, clones
   `pi-hole/pi-hole`, runs its official installer (`basic-install.sh`).
   **Point Pi-hole's upstream DNS at `127.0.0.1#5353` here.**
3. **`unbound-setup.sh`** — creates the `unbound` system user/group
   (uid/gid 88) and installs its build dependencies.
4. **`unbound-latest.sh`** — downloads, builds, and installs Unbound
   1.26.0 from source, fetches root hints and the DNSSEC trust anchor,
   runs `unbound-control-setup`.
5. **`adlist.sh`** — reads `blocklist.txt` (tracked in this repo) and
   loads its URLs into `gravity.db`.
6. **`pihole-update.sh`** — `pihole -up` then `pihole -g -f`.

There is no longer a script that deploys `unbound.conf`/the systemd units,
sets `pihole-FTL.conf`/`dnsmasq`/`/etc/hosts`, or enables/restarts
`unbound`/`roothints.timer` — that was `post-install.sh`, removed. On a
host where those units are already installed and enabled (true of the
currently-provisioned box), nothing above needs it. On a fresh host, none
of that setup happens unless you do it by hand or restore the script —
see below.

### Lighttpd HTTPS (manual, optional)

```
mkdir /etc/lighttpd/certs
openssl req -x509 -nodes -days 7300 -newkey rsa:2048 -sha256 \
  -keyout /etc/lighttpd/certs/server.pem -out /etc/lighttpd/certs/server.pem
chmod 600 /etc/lighttpd/certs/server.pem
```

Add `mod_openssl` to `server.modules` in `/etc/lighttpd/lighttpd.conf`, then:

```
$SERVER["socket"] == ":443" {
    ssl.engine = "enable"
    ssl.pemfile = "/etc/lighttpd/certs/server.pem"
}
```

```
sudo systemctl restart lighttpd
```

## State of this repo

`unbound.conf` and `unbound.service` are tracked in this repo again (as
plain files at the repo root, matching the live `/etc/unbound/unbound.conf`
and `/etc/systemd/system/unbound.service` exactly) — but **no script
deploys, enables, or reloads them.** `conf/`, `services/`, and
`post-install.sh` (which used to do that copying) were removed earlier and
haven't been restored. The currently-provisioned host works because those
files are already live under `/etc/systemd/system` and `/etc/unbound` from
before; a fresh clone onto a new host would need them copied into place
and `systemctl daemon-reload && systemctl enable --now unbound` run by
hand — nothing here does it automatically. `pihole.service`/`.timer`,
`roothints.service`, and `cleanup.service`/`.timer` are still not tracked
here at all.

`cleanup.sh`, `cleanup.service`, and `cleanup.timer` have all been removed
— the weekly log-truncation/cache-flush/service-restart maintenance pass
no longer runs, on any schedule or by hand. `pihole.service` and
`pihole.timer` (the daily 04:00 automatic `pihole -g` gravity rebuild)
have been removed too; `pihole-update.sh` still does the same `pihole -g`
call, just manually now. Neither removal touches `pihole-FTL.service`,
the actual DNS-resolving daemon installed by Pi-hole itself — that's
untouched and still running.

**Blocklist and regex sources moved local.** `adlist.sh` used to fetch its
URL list from an external GitLab repo
([kishansundar/pihole-adlist](https://gitlab.com/kishansundar/pihole-adlist))
over the network; that repo has been deleted, and `adlist.sh` now reads
`blocklist.txt` in this repo instead — no network dependency for the list
itself, no external single point of failure. `regex.txt` (Pi-hole regex
denylist patterns) and `regex.sh` (loads them into `gravity.db`'s
`domainlist` table, type `3`, then runs `pihole reloadlists`) are new,
tracked here for the first time.

## Script reference

| Script | Runs | Purpose |
|---|---|---|
| `apt-upgrade.sh` | install, ad hoc | System package update/upgrade/cleanup. |
| `pihole-setup.sh` | install once | Installs Pi-hole via its own official installer. |
| `unbound-setup.sh` | install once | Creates the `unbound` user/group, installs build deps. |
| `unbound-latest.sh` | install / version bumps | Builds and installs Unbound 1.26.0 from source. |
| `adlist.sh` | recurring, manual | Loads `blocklist.txt`'s URLs into `gravity.db`'s `adlist` table. |
| `regex.sh` | recurring, manual | Loads `regex.txt`'s patterns into `gravity.db`'s `domainlist` table (type `3`), then `pihole reloadlists`. |
| `pihole-update.sh` | recurring, manual | Updates Pi-hole core and force-rebuilds gravity. |
| `ulimit.sh` | on every Unbound start, via `unbound.service`'s `ExecStartPre` | Kernel network-buffer/TCP tuning (`sysctl -w`). |

## Maintenance

Automatic, via the one systemd timer still installed on the host:

- **`roothints.timer`** — monthly → re-`curl`s `named.cache` into
  `/etc/unbound/root.hints`.

Manual only, nothing schedules these:

- Gravity/blocklist rebuild (`pihole-update.sh`'s `pihole -g -f`) — used
  to also run daily via `pihole.timer`; that timer is gone.
- Blocklist source refresh (`adlist.sh`, from `blocklist.txt`)
- Regex denylist refresh (`regex.sh`, from `regex.txt`)
- Pi-hole core updates (`pihole-update.sh`)
- Unbound version upgrades (`unbound-latest.sh`)
- Log/cache housekeeping — used to run weekly via `cleanup.timer` →
  `cleanup.sh`; both are gone, and nothing replaces them.
- DNSSEC trust anchor refresh (only happens as a side effect of
  re-running `unbound-latest.sh`)
