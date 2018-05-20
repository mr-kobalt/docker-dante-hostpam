#!/bin/sh

set -e
if [ "$1" == "sockd" ]; then
  IFACE=$(ip route | grep default | awk '{print $5}')
  sed -i.bak "s/eth0/$IFACE/" "/etc/sockd.conf"
fi

exec "$@"
