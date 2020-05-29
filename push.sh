#!/bin/sh

set -eu
export LC_ALL=C

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

commitMsg=$(printf -- '%s\n%s' 'Updated sources:')
timestamp=$(date +"%D %T")

cd "${SCRIPT_DIR:?}"
git add "${SCRIPT_DIR:?}"
git commit -m "${commitMsg:?} $timestamp "
git push origin master

