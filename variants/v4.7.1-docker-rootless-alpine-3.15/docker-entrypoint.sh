#!/bin/sh
set -eu
echo "Starting rootless dockerd"
PATH=/home/user/bin:/sbin:/usr/sbin:$PATH dockerd-rootless.sh &
echo "Starting code-server"
exec code-server --bind-addr 0.0.0.0:8080 --disable-telemetry --disable-update-check