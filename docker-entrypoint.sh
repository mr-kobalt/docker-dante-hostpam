#!/bin/sh

set -e

if [ "$1" == "sockd" ]; then
  if [ -z "$DEBUG" ]; then
    export DEBUG=0
  fi
  sed -i "s/{DEBUG}/$DEBUG/" "/etc/sockd.conf"

  if [ -z "$EXTERNAL_INTERFACE" ]; then
    export EXTERNAL_INTERFACE=$(ip route | grep default | awk '{print $5}')
  fi
  sed -i "s/{EXTERNAL_INTERFACE}/$EXTERNAL_INTERFACE/" "/etc/sockd.conf"

  if [ -z "$INTERNAL_INTERFACE" ]; then
    export INTERNAL_INTERFACE="0.0.0.0"
  fi
  sed -i "s/{INTERNAL_INTERFACE}/$INTERNAL_INTERFACE/" "/etc/sockd.conf"

  if [ -z "$TCP_PORT" ]; then
    export TCP_PORT=1080
  fi
  sed -i "s/{TCP_PORT}/$TCP_PORT/" "/etc/sockd.conf"

  if [ -z "$UDP_PORT" ]; then
    export UDP_PORT=40000-45000
  fi
  sed -i "s/{UDP_PORT}/$UDP_PORT/" "/etc/sockd.conf"

  if [ -z "$USER" ]; then
    export USER=sockd
  fi
  sed -i "s/{USER}/$USER/" "/etc/sockd.conf"
fi

exec "$@"
