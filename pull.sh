#!/bin/sh

set -eu
export LC_ALL=C

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

cd "${SCRIPT_DIR:?}"
git fetch --all
git clean -df
git pull 
git reset --hard origin/master