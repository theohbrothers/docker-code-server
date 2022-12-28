@'
#!/bin/sh
set -eu

'@

if ($VARIANT['_metadata']['base_tag']) {
    # Incremental build
    foreach ($c in $VARIANT['_metadata']['components']) {
        if ($c -eq 'docker') {
@'
echo "Starting dockerd"
sudo rm -fv /var/run/docker.pid
sudo dockerd &

'@
        }
        if ($c -eq 'docker-rootless') {
@'
echo "Starting rootless dockerd"
PATH=/home/user/bin:/sbin:/usr/sbin:$PATH dockerd-rootless.sh &

'@
        }
    }
}

@'
echo "Starting code-server"
exec code-server --bind-addr 0.0.0.0:8080 --disable-telemetry --disable-update-check
'@
