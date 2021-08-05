#!/bin/sh

version=1.13.1

wget https://nlnetlabs.nl/downloads/unbound/unbound-${version}.tar.gz

tar -xzf unbound-${version}.tar.gz && rm -Rfr unbound-${version}.tar.gz
rm -Rfr unbound-stable
mv unbound-${version} unbound-stable
cd ~/unbound-stable
