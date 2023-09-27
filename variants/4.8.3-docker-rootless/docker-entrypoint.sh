#!/bin/sh
set -eu

# See: https://github.com/docker-library/official-images#consistency
if [ "$#" -eq 0 ] || [ "${1#-}" != "$1" ]; then
    set -- code-server "$@"
fi
if [ "$1" = 'code-server' ]; then
    # Start rootless docker
    # See: https://github.com/moby/moby/blob/v20.10.22/contrib/dockerd-rootless.sh
    # See: https://github.com/docker-library/docker/blob/master/20.10/dind/dockerd-entrypoint.sh
    echo "Starting rootless dockerd"
    rootlesskit \
        --net="${DOCKERD_ROOTLESS_ROOTLESSKIT_NET:-vpnkit}" \
        --mtu="${DOCKERD_ROOTLESS_ROOTLESSKIT_MTU:-1500}" \
        --disable-host-loopback \
        --port-driver="${DOCKERD_ROOTLESS_ROOTLESSKIT_PORT_DRIVER:-builtin}" \
        --copy-up=/etc \
        --copy-up=/run \
        --propagation=rslave \
        ${DOCKERD_ROOTLESS_ROOTLESSKIT_FLAGS:-} \
        dockerd &

    echo "Starting code-server"
    exec code-server "$@"
fi
exec "$@"
