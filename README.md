# docker-code-server

[![github-actions](https://github.com/theohbrothers/docker-code-server/workflows/ci-master-pr/badge.svg)](https://github.com/theohbrothers/docker-code-server/actions)
[![github-release](https://img.shields.io/github/v/release/theohbrothers/docker-code-server?style=flat-square)](https://github.com/theohbrothers/docker-code-server/releases/)
[![docker-image-size](https://img.shields.io/docker/image-size/theohbrothers/docker-code-server/latest)](https://hub.docker.com/r/theohbrothers/docker-code-server)

Dockerized [`code-server`](https://github.com/coder/code-server).

## Tags

| Tag | Dockerfile Build Context |
|:-------:|:---------:|
| `:4.20.0`, `:latest` | [View](variants/4.20.0) |
| `:4.20.0-docker` | [View](variants/4.20.0-docker) |
| `:4.20.0-docker-go-1.20.13` | [View](variants/4.20.0-docker-go-1.20.13) |
| `:4.20.0-docker-rootless` | [View](variants/4.20.0-docker-rootless) |
| `:4.20.0-docker-rootless-go-1.20.13` | [View](variants/4.20.0-docker-rootless-go-1.20.13) |
| `:4.19.1` | [View](variants/4.19.1) |
| `:4.19.1-docker` | [View](variants/4.19.1-docker) |
| `:4.19.1-docker-go-1.20.13` | [View](variants/4.19.1-docker-go-1.20.13) |
| `:4.19.1-docker-rootless` | [View](variants/4.19.1-docker-rootless) |
| `:4.19.1-docker-rootless-go-1.20.13` | [View](variants/4.19.1-docker-rootless-go-1.20.13) |
| `:4.18.0` | [View](variants/4.18.0) |
| `:4.18.0-docker` | [View](variants/4.18.0-docker) |
| `:4.18.0-docker-go-1.20.13` | [View](variants/4.18.0-docker-go-1.20.13) |
| `:4.18.0-docker-rootless` | [View](variants/4.18.0-docker-rootless) |
| `:4.18.0-docker-rootless-go-1.20.13` | [View](variants/4.18.0-docker-rootless-go-1.20.13) |
| `:4.17.1` | [View](variants/4.17.1) |
| `:4.17.1-docker` | [View](variants/4.17.1-docker) |
| `:4.17.1-docker-go-1.20.13` | [View](variants/4.17.1-docker-go-1.20.13) |
| `:4.17.1-docker-rootless` | [View](variants/4.17.1-docker-rootless) |
| `:4.17.1-docker-rootless-go-1.20.13` | [View](variants/4.17.1-docker-rootless-go-1.20.13) |
| `:4.16.1` | [View](variants/4.16.1) |
| `:4.16.1-docker` | [View](variants/4.16.1-docker) |
| `:4.16.1-docker-go-1.20.13` | [View](variants/4.16.1-docker-go-1.20.13) |
| `:4.16.1-docker-rootless` | [View](variants/4.16.1-docker-rootless) |
| `:4.16.1-docker-rootless-go-1.20.13` | [View](variants/4.16.1-docker-rootless-go-1.20.13) |
| `:4.15.0` | [View](variants/4.15.0) |
| `:4.15.0-docker` | [View](variants/4.15.0-docker) |
| `:4.15.0-docker-go-1.20.13` | [View](variants/4.15.0-docker-go-1.20.13) |
| `:4.15.0-docker-rootless` | [View](variants/4.15.0-docker-rootless) |
| `:4.15.0-docker-rootless-go-1.20.13` | [View](variants/4.15.0-docker-rootless-go-1.20.13) |
| `:4.14.1` | [View](variants/4.14.1) |
| `:4.14.1-docker` | [View](variants/4.14.1-docker) |
| `:4.14.1-docker-go-1.20.13` | [View](variants/4.14.1-docker-go-1.20.13) |
| `:4.14.1-docker-rootless` | [View](variants/4.14.1-docker-rootless) |
| `:4.14.1-docker-rootless-go-1.20.13` | [View](variants/4.14.1-docker-rootless-go-1.20.13) |
| `:4.13.0` | [View](variants/4.13.0) |
| `:4.13.0-docker` | [View](variants/4.13.0-docker) |
| `:4.13.0-docker-go-1.20.13` | [View](variants/4.13.0-docker-go-1.20.13) |
| `:4.13.0-docker-rootless` | [View](variants/4.13.0-docker-rootless) |
| `:4.13.0-docker-rootless-go-1.20.13` | [View](variants/4.13.0-docker-rootless-go-1.20.13) |
| `:4.12.0` | [View](variants/4.12.0) |
| `:4.12.0-docker` | [View](variants/4.12.0-docker) |
| `:4.12.0-docker-go-1.20.13` | [View](variants/4.12.0-docker-go-1.20.13) |
| `:4.12.0-docker-rootless` | [View](variants/4.12.0-docker-rootless) |
| `:4.12.0-docker-rootless-go-1.20.13` | [View](variants/4.12.0-docker-rootless-go-1.20.13) |
| `:4.11.0` | [View](variants/4.11.0) |
| `:4.11.0-docker` | [View](variants/4.11.0-docker) |
| `:4.11.0-docker-go-1.20.13` | [View](variants/4.11.0-docker-go-1.20.13) |
| `:4.11.0-docker-rootless` | [View](variants/4.11.0-docker-rootless) |
| `:4.11.0-docker-rootless-go-1.20.13` | [View](variants/4.11.0-docker-rootless-go-1.20.13) |

Base variants are based on `alpine`, and include `npm 8` and `nodejs 16` (to run `code-server`), `pwsh`, and basic tools. E.g. `4.20.0`

Incremental variants include additional tools and their `code` extensions:

- `docker`: [docker](https://docs.docker.com/engine/)
- `docker-rootless`: [Rootless docker](https://docs.docker.com/engine/security/rootless/)
- `go`: [go](https://go.dev)

## Usage

### Base variant(s)

```sh
docker run --name code-server --rm -it -p 127.0.0.1:8080:8080 theohbrothers/docker-code-server:4.20.0
# code-server is now available at http://127.0.0.1:8080. To login, use the password in the config file:
docker exec code-server sh -c 'cat ~/.config/code-server/config.yaml'
```

To disable password authentication, use `--auth=none`:

```sh
docker run --name code-server --rm -it -p 127.0.0.1:8080:8080 theohbrothers/docker-code-server:4.20.0 --bind-addr=0.0.0.0:8080 --auth=none --disable-telemetry --disable-update-check
```

### `docker` variant(s)

```sh
docker run --name code-server --rm -it --privileged -v docker:/var/lib/docker -p 127.0.0.1:8080:8080 theohbrothers/docker-code-server:4.20.0-docker
# code-server is now available at http://127.0.0.1:8080. To login, use the password in the config file:
docker exec code-server sh -c 'cat ~/.config/code-server/config.yaml'
```

To disable password authentication, use `--auth=none`:

```sh
docker run --name code-server --rm -it -p 127.0.0.1:8080:8080 theohbrothers/docker-code-server:4.20.0-docker --bind-addr=0.0.0.0:8080 --auth=none --disable-telemetry --disable-update-check
```

#### docker buildx

To build multi-arch images using [`docker buildx`](https://docs.docker.com/engine/reference/commandline/buildx/), the host must have kernel >= `4.8`, and must have setup `qemu` in the kernel (see [here](https://github.com/docker/setup-qemu-action)):

```sh
# This must be run on each reboot on the host to setup qemu
docker run --rm --privileged tonistiigi/binfmt:latest --install all
```

Then, `buildx` multi-arch builds are now available in the container:

```sh
# Create a builder and use it
docker buildx create --name mybuilder --driver docker-container
docker buildx use mybuilder
docker buildx ls # Should show several platforms
docker buildx inspect mybuilder # Should show several platforms

# Build
docker buildx build ...
```

### `docker-rootless` variant(s)

```sh
docker run --name code-server --rm -it --privileged -p 127.0.0.1:8080:8080 theohbrothers/docker-code-server:4.20.0-docker-rootless
# code-server is now available at http://127.0.0.1:8080. To login, use the password in the config file:
docker exec code-server sh -c 'cat ~/.config/code-server/config.yaml'
```

To start code-server without password authentication, use `--auth=none`:

```sh
docker run --name code-server --rm -it -p 127.0.0.1:8080:8080 theohbrothers/docker-code-server:4.20.0-docker-rootless --bind-addr=0.0.0.0:8080 --auth=none --disable-telemetry --disable-update-check
```

To build multi-arch images using `docker buildx`, see [here](#docker-buildx).

## Notes

- See official docs for code-server configuration: https://github.com/coder/code-server/blob/main/docs/FAQ.md#how-does-the-config-file-work
- The default user is named `user` with UID `1000`. To escalate as `root`, use `sudo`.
- Users should provision their own configuration files at entrypoint. Examples include dotfiles such as `~/.bash_aliases`, `~/.gitconfig`, and `code` configs such as `~/.local/share/code-server/User/keybindings.json` and `~/.local/share/code-server/User/settings.json`. It is recommended to use any of these [utilities](https://dotfiles.github.io/utilities/) for managing dotfiles.
<!-- - To ensure `bash-completion` works, ensure `/etc/profile.d/bash_completion.sh` is sourced by `~/.bashrc`. When `exec`ing into the container, use a login shell (E.g. `docker exec -it <container> bash -l`). -->
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

### Variant versions

[versions.json](generate/definitions/versions.json) contains a list of [Semver](https://semver.org/) versions, one per line.

To update versions in `versions.json`:

```powershell
./Update-Versions.ps1
```

To update versions in `versions.json`, and open a PR for each changed version, and merge successful PRs one after another (to prevent merge conflicts), and finally create a tagged release and close milestone:

```powershell
$env:GITHUB_TOKEN = 'xxx'
./Update-Versions.ps1 -PR -AutoMergeQueue -AutoRelease
```

To perform a dry run, use `-WhatIf`.
