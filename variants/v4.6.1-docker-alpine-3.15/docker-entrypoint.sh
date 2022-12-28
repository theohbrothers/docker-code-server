#!/bin/sh
set -eu
echo "Starting dockerd"
sudo rm -fv /var/run/docker.pid
sudo dockerd &
echo "Starting code-server"
exec code-server --bind-addr 0.0.0.0:8080 --disable-telemetry --disable-update-check