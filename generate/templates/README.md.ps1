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
| ``:$( $_['tag'] )``, ``:latest`` | [View](variants/$( $_['tag'] ) ) |

"@
    }else {
@"
| ``:$( $_['tag'] )`` | [View](variants/$( $_['tag'] ) ) |

"@
    }
}) -join ''
)
Base variants do not contain additional tools. E.g. ``$( $VARIANTS | ? { $_['tag_as_latest'] } | Select-Object -ExpandProperty tag )``.

Incremental variants contain additional tools. E.g. ``$( $VARIANTS | ? { $_['_metadata']['base_tag'] } | Select-Object -First 1 | Select-Object -ExpandProperty tag )``:

- ``docker``: [docker](https://docs.docker.com/engine/)
- ``docker-rootless``: [Rootless docker](https://docs.docker.com/engine/security/rootless/)
- ``pwsh``: [Powershell](https://github.com/PowerShell/PowerShell)


"@
@"
## Usage

To run a base variant:

``````sh
docker run --name code-server --rm -it -p 127.0.0.1:8080:8080 theohbrothers/docker-code-server:$( $VARIANTS | ? { $_['tag_as_latest'] } | Select-Object -ExpandProperty tag )
``````

To run an incremental variant:

``````sh
# docker or docker-rootless
docker run --name code-server --rm -it --privileged -p 127.0.0.1:8080:8080 theohbrothers/docker-code-server:$( $VARIANTS | ? { $_['_metadata']['components'] -contains 'docker' } | Select-Object -First 1 | Select-Object -ExpandProperty tag )

# pwsh
docker run --name code-server --rm -it --privileged -p 127.0.0.1:8080:8080 theohbrothers/docker-code-server:$( $VARIANTS | ? { $_['_metadata']['components'] -match 'pwsh' } | Select-Object -First 1 | Select-Object -ExpandProperty tag )
``````

``code-server`` is now available at http://127.0.0.1:8080. To login, use the password in the config file:

``````sh
docker exec code-server sh -c 'cat ~/.config/code-server/config.yaml'
``````


"@

@'
## Notes

- The default user is named `user` with UID `1000`. To escalate as `root`, use `sudo`.
- Users should provision their own configuration files at entrypoint. Examples include dot files such as `~/.bash_aliases`, `~/.gitconfig`, and `code` configs such as `~/.local/share/code-server/User/keybindings.json` and `~/.local/share/code-server/User/settings.json`.
- To ensure `bash-completion` works, ensure `/etc/profile.d/bash_completion.sh` is sourced by `~/.bashrc`. When `exec`ing into the container, use a login shell (E.g. `docker exec -it <container> bash -l`).

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
