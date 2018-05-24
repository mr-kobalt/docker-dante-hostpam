#!/bin/sh

set -e

if [ "$1" == "sockd" ]; then
  if [ -z "$DEBUG"]; then
    export DEBUG=0
  fi
  sed -i "s/{DEBUG}/$DEBUG/" "/etc/sockd.conf"

  if [ -z "$EXTERNAL_IFACE" ]; then
    export EXTERNAL_IFACE=$(ip route | grep default | awk '{print $5}')
  fi
  sed -i "s/{EXTERNAL_IFACE}/$EXTERNAL_IFACE/" "/etc/sockd.conf"

  if [ -z "$INTERNAL_IFACE" ]; then
    export INTERNAL_IFACE="0.0.0.0"
  fi
  sed -i "s/{INTERNAL_IFACE}/$INTERNAL_IFACE/" "/etc/sockd.conf"

  if [ -z "$PORT"]; then
    export PORT=1080
  fi
  sed -i "s/{PORT}/$PORT/" "/etc/sockd.conf"

  if [ -z "$USER"]; then
    export USER=sockd
  fi
  sed -i "s/{USER}/$USER/" "/etc/sockd.conf"
fi

exec "$@"
