#!/bin/sh

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

echo "------------------------------------------"
echo "Copying... *.service"
cp -rf ${SCRIPT_DIR:?}/services/unbound.service /etc/systemd/system/unbound.service
cp -rf ${SCRIPT_DIR:?}/services/pihole.service /etc/systemd/system/pihole.service
cp -rf ${SCRIPT_DIR:?}/services/roothints.service /etc/systemd/system/roothints.service
cp -rf ${SCRIPT_DIR:?}/services/cleanup.service /etc/systemd/system/cleanup.service
echo "------------------------------------------"
echo "Copying... *.timer"
cp -rf ${SCRIPT_DIR:?}/services/pihole.timer /etc/systemd/system/pihole.timer
cp -rf ${SCRIPT_DIR:?}/services/roothints.timer /etc/systemd/system/roothints.timer
cp -rf ${SCRIPT_DIR:?}/services/cleanup.timer /etc/systemd/system/cleanup.timer
echo "------------------------------------------"
echo "Copying... unbound.conf"
cp -rf ${SCRIPT_DIR:?}/conf/unbound.conf /etc/unbound/unbound.conf
echo "------------------------------------------"
echo "Done."
echo "------------------------------------------"
