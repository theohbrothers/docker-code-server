#!/bin/sh
set -eu
echo "Starting code-server"
exec code-server --bind-addr 0.0.0.0:8080 --disable-telemetry --disable-update-check