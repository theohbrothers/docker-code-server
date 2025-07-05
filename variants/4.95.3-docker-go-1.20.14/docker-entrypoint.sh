#!/bin/sh
set -eu

# See: https://github.com/docker-library/official-images#consistency
if [ "$#" -eq 0 ] || [ "${1#-}" != "$1" ]; then
    set -- code-server "$@"
fi
if [ "$1" = 'code-server' ]; then
    echo "Starting dockerd"
    sudo rm -fv /var/run/docker.pid
    sudo dockerd &

    echo "Starting code-server"
    exec code-server "$@"
fi
exec "$@"
