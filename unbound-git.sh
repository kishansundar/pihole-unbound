#!/bin/sh

git clone https://github.com/NLnetLabs/unbound.git ~/unbound-git
cd ~/unbound-git
git fetch --all
git clean -df
git pull 
git reset --hard origin/master
