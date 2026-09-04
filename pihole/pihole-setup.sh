#!/bin/bash

# Pinned to a specific release tag rather than tracking the default branch's
# HEAD — verified this tag exists (git ls-remote --tags) before pinning.
# Was v6.4.3, the "Latest" release as of this fix; override with
# PIHOLE_VERSION=vX.Y.Z if a newer one is out.
version="${PIHOLE_VERSION:-v6.4.3}"

sudo apt install git build-essential wget -y

if [ -d ~/Pi-hole ]; then
  echo "~/Pi-hole already exists from a previous run — removing before starting."
  rm -Rf ~/Pi-hole
fi

git clone --branch "$version" --depth 1 https://github.com/pi-hole/pi-hole.git ~/Pi-hole \
  || { echo "ERROR: clone of pi-hole ${version} failed" >&2; exit 1; }

cd ~/Pi-hole/automated\ install/ || exit 1
sudo bash basic-install.sh \
  || { echo "ERROR: basic-install.sh failed — leaving ~/Pi-hole in place for inspection" >&2; exit 1; }

cd ~
rm -Rf ~/Pi-hole
