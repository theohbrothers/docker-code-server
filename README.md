# docker-code-server

[![github-actions](https://github.com/theohbrothers/docker-code-server/workflows/ci-master-pr/badge.svg)](https://github.com/theohbrothers/docker-code-server/actions)
[![github-release](https://img.shields.io/github/v/release/theohbrothers/docker-code-server?style=flat-square)](https://github.com/theohbrothers/docker-code-server/releases/)
[![docker-image-size](https://img.shields.io/docker/image-size/theohbrothers/docker-code-server/latest)](https://hub.docker.com/r/theohbrothers/docker-code-server)

Dockerized [`code-server`](https://github.com/coder/code-server).

## Tags

| Tag | Dockerfile Build Context |
|:-------:|:---------:|
| `:v4.9.1-alpine-3.15`, `:latest` | [View](variants/v4.9.1-alpine-3.15 ) |
| `:v4.8.3-alpine-3.15` | [View](variants/v4.8.3-alpine-3.15 ) |
| `:v4.8.3-pwsh-7.3.1-alpine-3.15` | [View](variants/v4.8.3-pwsh-7.3.1-alpine-3.15 ) |
| `:v4.8.3-pwsh-7.2.8-alpine-3.15` | [View](variants/v4.8.3-pwsh-7.2.8-alpine-3.15 ) |
| `:v4.8.3-pwsh-7.1.7-alpine-3.15` | [View](variants/v4.8.3-pwsh-7.1.7-alpine-3.15 ) |
| `:v4.8.3-pwsh-7.0.13-alpine-3.15` | [View](variants/v4.8.3-pwsh-7.0.13-alpine-3.15 ) |
| `:v4.7.1-alpine-3.15` | [View](variants/v4.7.1-alpine-3.15 ) |
| `:v4.6.1-alpine-3.15` | [View](variants/v4.6.1-alpine-3.15 ) |

- `pwsh`: Powershell

## Usage

```sh
# code-server available at http://127.0.0.1:8080
docker run --name code-server -it -p 127.0.0.1:8080:8080 theohbrothers/docker-code-server:latest
# Login using the password in the config file
docker exec code-server sh -c 'cat ~/.config/code-server/config.yaml'
```

## Development

Requires Windows `powershell` or [`pwsh`](https://github.com/PowerShell/PowerShell).

```powershell
# Install Generate-DockerImageVariants module: https://github.com/theohbrothers/Generate-DockerImageVariants
Install-Module -Name Generate-DockerImageVariants -Repository PSGallery -Scope CurrentUser -Force -Verbose

# Edit ./generate templates

# Generate the variants
Generate-DockerImageVariants .
```
