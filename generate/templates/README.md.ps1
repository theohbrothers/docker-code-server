@"
# docker-code-server

[![github-actions](https://github.com/theohbrothers/docker-code-server/workflows/ci-master-pr/badge.svg)](https://github.com/theohbrothers/docker-code-server/actions)
[![github-release](https://img.shields.io/github/v/release/theohbrothers/docker-code-server?style=flat-square)](https://github.com/theohbrothers/docker-code-server/releases/)
[![docker-image-size](https://img.shields.io/docker/image-size/theohbrothers/docker-code-server/latest)](https://hub.docker.com/r/theohbrothers/docker-code-server)

Dockerized [``code-server``](https://github.com/coder/code-server).

## Tags

| Tag | Dockerfile Build Context |
|:-------:|:---------:|
$(
($VARIANTS | % {
    if ( $_['tag_as_latest'] ) {
@"
| ``:$( $_['tag'] )``, ``:latest`` | [View](variants/$( $_['tag'] )) |

"@
    }else {
@"
| ``:$( $_['tag'] )`` | [View](variants/$( $_['tag'] )) |

"@
    }
}) -join ''
)
Base variants include ``npm 8`` and ``nodejs 16`` to run ``code-server``, ``pwsh``, and basic tools. E.g. ``$( $VARIANTS | ? { $_['tag_as_latest'] } | Select-Object -First 1 | Select-Object -ExpandProperty tag )``.

Incremental variants include additional tools and their ``code`` extensions. E.g. ``$( $VARIANTS | ? { $_['_metadata']['base_tag'] } | Select-Object -First 1 | Select-Object -ExpandProperty tag )``:

- ``docker``: [docker](https://docs.docker.com/engine/)
- ``docker-rootless``: [Rootless docker](https://docs.docker.com/engine/security/rootless/)
- ``go``: [go](https://go.dev)


"@
@"
## Usage

### Base variant(s)

``````sh
docker run --name code-server --rm -it -p 127.0.0.1:8080:8080 theohbrothers/docker-code-server:$( $VARIANTS | ? { $_['tag_as_latest'] } | Select-Object -ExpandProperty tag )
# code-server is now available at http://127.0.0.1:8080. To login, use the password in the config file:
docker exec code-server sh -c 'cat ~/.config/code-server/config.yaml'
``````

### ``docker`` variant(s)

``````sh
docker run --name code-server --rm -it --privileged -p 127.0.0.1:8080:8080 theohbrothers/docker-code-server:$( $VARIANTS | ? { $_['_metadata']['components'] -contains 'docker' } | Select-Object -First 1 | Select-Object -ExpandProperty tag )
# code-server is now available at http://127.0.0.1:8080. To login, use the password in the config file:
docker exec code-server sh -c 'cat ~/.config/code-server/config.yaml'
``````

To build multi-arch images using [``buildx``](https://docs.docker.com/engine/reference/commandline/buildx/), the host must have kernel >= ``4.8``, and must [setup ``qemu`` in the kernel](https://github.com/docker/setup-qemu-action) on each reboot:

``````sh
docker run --rm --privileged tonistiigi/binfmt:latest --install all
``````

Then, ``buildx`` multi-arch builds are now available in the container:

``````sh
# Create a builder and use it
docker buildx create --name mybuilder --driver docker-container
docker buildx use mybuilder
docker buildx ls
docker buildx inspect mybuilder # Should show several platforms

# Build
docker buildx build .
``````

### ``docker-rootless`` variant(s)

``````sh
docker run --name code-server --rm -it --privileged -p 127.0.0.1:8080:8080 theohbrothers/docker-code-server:$( $VARIANTS | ? { $_['_metadata']['components'] -contains 'docker-rootless' } | Select-Object -First 1 | Select-Object -ExpandProperty tag )
# code-server is now available at http://127.0.0.1:8080. To login, use the password in the config file:
docker exec code-server sh -c 'cat ~/.config/code-server/config.yaml'

# The docker-rootless variant executes dockerd in its own user, mount, and network namespaces, see https://docs.docker.com/engine/security/rootless/#tips-for-debugging. To enter the namespace, run:
docker exec -it code-server sh -c 'nsenter -U --preserve-credentials -n -m -t `$( cat `$XDG_RUNTIME_DIR/docker.pid )'
```````

To build multi-arch images using [``buildx``](https://docs.docker.com/engine/reference/commandline/buildx/), the host must have kernel >= ``4.8``, and must [setup ``qemu`` in the kernel](https://github.com/docker/setup-qemu-action) on each reboot:

``````sh
docker run --rm --privileged tonistiigi/binfmt:latest --install all
``````

Then, ``buildx`` multi-arch builds are now available in the container:

``````sh
# Create a builder and use it
docker buildx create --name mybuilder --driver docker-container
docker buildx use mybuilder
docker buildx ls
docker buildx inspect mybuilder # Should show several platforms

# Build
docker buildx build .
``````


"@

@'
## Notes

- The default user is named `user` with UID `1000`. To escalate as `root`, use `sudo`.
- Users should provision their own configuration files at entrypoint. Examples include dot files such as `~/.bash_aliases`, `~/.gitconfig`, and `code` configs such as `~/.local/share/code-server/User/keybindings.json` and `~/.local/share/code-server/User/settings.json`.
- To ensure `bash-completion` works, ensure `/etc/profile.d/bash_completion.sh` is sourced by `~/.bashrc`. When `exec`ing into the container, use a login shell (E.g. `docker exec -it <container> bash -l`).
- To install a custom version of a `code` extension, set `"extensions.autoCheckUpdates": true` in `settings.json`. Under `Extensions` view, click the extension's cogwheel and select `Install Another Version...`.

## Development

Requires Windows `powershell` or [`pwsh`](https://github.com/PowerShell/PowerShell).

```powershell
# Install Generate-DockerImageVariants module: https://github.com/theohbrothers/Generate-DockerImageVariants
Install-Module -Name Generate-DockerImageVariants -Repository PSGallery -Scope CurrentUser -Force -Verbose

# Edit ./generate templates

# Generate the variants
Generate-DockerImageVariants .
```

'@
