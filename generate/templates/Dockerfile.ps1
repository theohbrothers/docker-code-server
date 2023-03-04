if (!$VARIANT['_metadata']['base_tag']) {
    # Base image
    @"
# syntax=docker/dockerfile:1
# The syntax=docker/dockerfile:1 line above is needed for passing secrets to the build

FROM $( $VARIANT['_metadata']['distro'] ):$( $VARIANT['_metadata']['distro_version'] )
ARG TARGETPLATFORM
ARG BUILDPLATFORM
RUN echo "I am running on `$BUILDPLATFORM, building for `$TARGETPLATFORM"

RUN --mount=type=secret,id=GITHUB_TOKEN \
    DEPS='alpine-sdk bash libstdc++ libc6-compat python3' \
    && apk add --no-cache `$DEPS \
    # Constraint to npm 8, or else npm will fail with 'npm ERR! `python` is not a valid npm option'. See: https://stackoverflow.com/questions/74522956/python-is-not-a-valid-npm-option and https://jubianchi.github.io/semver-check/#/~8/8
    && apk add --no-cache 'npm~8' 'nodejs~16' \
    && npm config set python python3 \
    && GITHUB_TOKEN=`$( cat /run/secrets/GITHUB_TOKEN ) npm install --global code-server@$( $VARIANT['_metadata']['package_version'] ) --unsafe-perm \
    # Fix missing dependencies. See: https://github.com/coder/code-server/issues/5530
    && cd /usr/local/lib/node_modules/code-server/lib/vscode && GITHUB_TOKEN=`$( cat /run/secrets/GITHUB_TOKEN ) npm install --legacy-peer-deps \
    && code-server --version \
    && apk del `$DEPS

# Install tools
RUN apk add --no-cache bash bash-completion ca-certificates curl gnupg git git-lfs iotop jq less lsblk make nano openssh-client openssl p7zip rsync tree yq

RUN apk add --no-cache sudo
RUN adduser -u 1000 --gecos '' -D user
RUN echo 'user ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/user

# Install common extensions
USER user
# beautify - code formatter
RUN code-server --install-extension hookyqr.beautify@1.4.11
# docker
RUN code-server --install-extension ms-azuretools.vscode-docker@1.18.0
# firefox
RUN code-server --install-extension firefox-devtools.vscode-firefox-debug@2.9.1
# git
RUN code-server --install-extension donjayamanne.githistory@0.6.19
RUN code-server --install-extension eamodio.gitlens@11.6.0
# jinja
RUN code-server --install-extension samuelcolvin.jinjahtml@0.16.0
RUN code-server --install-extension wholroyd.jinja@0.0.8
# kubernetes
RUN code-server --install-extension ms-kubernetes-tools.vscode-kubernetes-tools@1.3.11
# markdown
RUN code-server --install-extension bierner.markdown-preview-github-styles@0.1.6
RUN code-server --install-extension DavidAnson.vscode-markdownlint@0.43.2
# prettier - code formatter
RUN code-server --install-extension esbenp.prettier-vscode@9.0.0
# svg
RUN code-server --install-extension jock.svg@1.4.17
# terraform
RUN code-server --install-extension hashicorp.terraform@2.14.0
# toml
RUN code-server --install-extension bungcip.better-toml@0.3.2
# vscode
RUN code-server --install-extension vscode-icons-team.vscode-icons@11.13.0
# xml
RUN code-server --install-extension redhat.vscode-xml@0.18.0
# yaml
RUN code-server --install-extension redhat.vscode-yaml@1.9.1

# Add a default settings.json
USER user
COPY --chown=1000:1000 settings.json /home/user/.local/share/code-server/User/settings.json


"@
}else {
    # Incremental image
    @'
ARG BASE_IMAGE
FROM $BASE_IMAGE


'@
    foreach ($c in $VARIANT['_metadata']['components']) {
        if ($c -eq 'docker' -or $c -eq 'docker-rootless') {
            $DOCKER_VERSION = '20.10.23'
@"
# Install docker
# See: https://github.com/moby/moby/blob/v20.10.22/project/PACKAGERS.md
# Install docker-cli dependencies
USER root
RUN apk add --no-cache \
        ca-certificates \
        git \
        # Workaround for golang 1.15 not producing static binaries. See: https://github.com/containerd/containerd/issues/5824
        libc6-compat \
        openssh-client
# Install dockerd dependencies
RUN apk add --no-cache \
        btrfs-progs \
        e2fsprogs \
        e2fsprogs-extra \
        ip6tables \
        iptables \
        openssl \
        pigz \
        shadow-uidmap \
        xfsprogs \
        xz \
        zfs
# Add userns-remap support. See: https://docs.docker.com/engine/security/userns-remap/
RUN set -eux; \
    addgroup -S dockremap; \
    adduser -S -G dockremap dockremap; \
    echo 'dockremap:231072:65536' >> /etc/subuid; \
    echo 'dockremap:231072:65536' >> /etc/subgid
# Install docker
RUN set -eux; \
    case "`$( uname -m )" in \
        'x86_64') \
            URL='https://download.docker.com/linux/static/stable/x86_64/docker-$DOCKER_VERSION.tgz'; \
            ;; \
        'armhf') \
            URL='https://download.docker.com/linux/static/stable/armel/docker-$DOCKER_VERSION.tgz'; \
            ;; \
        'armv7') \
            URL='https://download.docker.com/linux/static/stable/armhf/docker-$DOCKER_VERSION.tgz'; \
            ;; \
        'aarch64') \
            URL='https://download.docker.com/linux/static/stable/aarch64/docker-$DOCKER_VERSION.tgz'; \
            ;; \
        # These architectures are no longer supported as of docker 20.10.x
        # 'ppc64le') \
        # 	URL='https://download.docker.com/linux/static/stable/ppc64le/docker-$DOCKER_VERSION.tgz'; \
        # 	;; \
        # 's390x') \
        # 	URL='https://download.docker.com/linux/static/stable/s390x/docker-$DOCKER_VERSION.tgz'; \
        # 	;; \
        *) \
            echo "Architecture not supported"; \
            exit 1; \
            ;; \
    esac; \
    wget -q "`$URL" -O docker.tgz; \
    tar -xvf docker.tgz --strip-components=1 --no-same-owner --no-same-permissions -C /usr/local/bin; \
    ls -al /usr/local/bin; \
    rm -v docker.tgz; \
    containerd --version; \
    ctr --version; \
    docker --version; \
    dockerd --version; \
    runc --version
# Install bash completion
RUN wget -q https://raw.githubusercontent.com/docker/cli/v$DOCKER_VERSION/contrib/completion/bash/docker -O /usr/share/bash-completion/completions/docker
# Post-install docker. See: https://docs.docker.com/engine/install/linux-postinstall/
RUN set -eux; \
    addgroup docker; \
    adduser user docker;
VOLUME /var/lib/docker


"@
            if ($c -eq 'docker-rootless') {
@"
# Install rootless docker. See: https://docs.docker.com/engine/security/rootless/
USER root
RUN apk add --no-cache iproute2 fuse-overlayfs
RUN set -eux; \
    echo user:100000:65536 >> /etc/subuid; \
    echo user:100000:65536 >> /etc/subgid
RUN set -eux; \
    case "`$( uname -m )" in \
        'x86_64') \
            URL='https://download.docker.com/linux/static/stable/x86_64/docker-rootless-extras-$DOCKER_VERSION.tgz'; \
            ;; \
        'aarch64') \
            URL='https://download.docker.com/linux/static/stable/aarch64/docker-rootless-extras-$DOCKER_VERSION.tgz'; \
            ;; \
        'armv7') \
            URL='https://download.docker.com/linux/static/stable/armhf/docker-rootless-extras-$DOCKER_VERSION.tgz'; \
            ;; \
        'aarch64') \
            URL='https://download.docker.com/linux/static/stable/aarch64/docker-rootless-extras-$DOCKER_VERSION.tgz'; \
            ;; \
        *) \
            echo "Architecture not supported"; \
            exit 1; \
            ;; \
    esac; \
    wget -q "`$URL" -O docker-rootless-extras.tgz; \
    tar -xvf docker-rootless-extras.tgz --strip-components=1 --no-same-owner --no-same-permissions -C /usr/local/bin \
        'docker-rootless-extras/rootlesskit' \
        'docker-rootless-extras/rootlesskit-docker-proxy' \
        'docker-rootless-extras/vpnkit' \
    ; \
    ls -al /usr/local/bin; \
    rm -v docker-rootless-extras.tgz; \
    rootlesskit --version; \
    vpnkit --version
# Create XDG_RUNTIME_DIR
RUN mkdir /run/user && chmod 1777 /run/user
# Create /var/lib/docker
RUN mkdir -p /home/user/.local/share/docker && chown user:user /home/user/.local/share/docker
VOLUME /home/user/.local/share/docker
# Set env vars
ENV XDG_RUNTIME_DIR=/run/user/1000
ENV DOCKER_HOST=unix:///run/user/1000/docker.sock


"@
            }
@"
# Install docker-compose v1 (deprecated, but for backward compatibility)
USER root
RUN apk add --no-cache docker-compose


"@

$DOCKER_COMPOSE_VERSION = 'v2.15.1'
$checksums = $global:CACHE['docker-compose-checksums'] = if (!$global:CACHE.Contains('docker-compose-checksums')) {
    [System.Text.Encoding]::UTF8.GetString( (Invoke-WebRequest https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/checksums.txt).Content )
}else {
    $global:CACHE['docker-compose-checksums']
}
@"
# Install docker compose v2. See: https://github.com/docker/compose/releases/
USER root
RUN set -eux; \
    case "`$( uname -m )" in \
        'x86_64')  \
            URL=https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/$( $checksums -split "`n" | ? { $_ -match 'linux-x86_64' } | % { $_ -split '\s' } | Select-Object -Last 1 | % { $_.TrimStart('*') } ); \
            SHA256=$( $checksums -split "`n" | ? { $_ -match 'linux-x86_64' } | % { $_ -split '\s' } | Select-Object -First 1 ); \
            ;; \
        'armhf')  \
            URL=https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/$( $checksums -split "`n" | ? { $_ -match 'linux-armv6' } | % { $_ -split '\s' } | Select-Object -Last 1 | % { $_.TrimStart('*') } ); \
            SHA256=$( $checksums -split "`n" | ? { $_ -match 'linux-armv6' } | % { $_ -split '\s' } | Select-Object -First 1 ); \
            ;; \
        'armv7') \
            URL=https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/$( $checksums -split "`n" | ? { $_ -match 'linux-armv7' } | % { $_ -split '\s' } | Select-Object -Last 1 | % { $_.TrimStart('*') } ); \
            SHA256=$( $checksums -split "`n" | ? { $_ -match 'linux-armv7' } | % { $_ -split '\s' } | Select-Object -First 1 ); \
            ;; \
        'aarch64') \
            URL=https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/$( $checksums -split "`n" | ? { $_ -match 'linux-aarch64' } | % { $_ -split '\s' } | Select-Object -Last 1 | % { $_.TrimStart('*') } ); \
            SHA256=$( $checksums -split "`n" | ? { $_ -match 'linux-aarch64' } | % { $_ -split '\s' } | Select-Object -First 1 ); \
            ;; \
        'ppc64le') \
            URL=https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/$( $checksums -split "`n" | ? { $_ -match 'linux-ppc64le' } | % { $_ -split '\s' } | Select-Object -Last 1 | % { $_.TrimStart('*') } ); \
            SHA256=$( $checksums -split "`n" | ? { $_ -match 'linux-ppc64le' } | % { $_ -split '\s' } | Select-Object -First 1 ); \
            ;; \
        'riscv64') \
            URL=https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/$( $checksums -split "`n" | ? { $_ -match 'linux-riscv64' } | % { $_ -split '\s' } | Select-Object -Last 1 | % { $_.TrimStart('*') } ); \
            SHA256=$( $checksums -split "`n" | ? { $_ -match 'linux-riscv64' } | % { $_ -split '\s' } | Select-Object -First 1 ); \
            ;; \
        's390x') \
            URL=https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/$( $checksums -split "`n" | ? { $_ -match 'linux-s390x' } | % { $_ -split '\s' } | Select-Object -Last 1 | % { $_.TrimStart('*') } ); \
            SHA256=$( $checksums -split "`n" | ? { $_ -match 'linux-s390x' } | % { $_ -split '\s' } | Select-Object -First 1 ); \
            ;; \
        *) \
            echo "Architecture not supported"; \
            exit 1; \
            ;; \
    esac; \
    wget -qO- "`$URL" > docker-compose \
    && sha256sum docker-compose | grep "^`$SHA256 " \
    && mkdir -pv /usr/libexec/docker/cli-plugins \
    && mv -v docker-compose /usr/libexec/docker/cli-plugins/docker-compose \
    && chmod +x /usr/libexec/docker/cli-plugins/docker-compose \
    && docker compose version


"@

$DOCKER_BUILDX_VERSION = 'v0.9.1'
$checksums = $global:CACHE['docker-buildx-checksums'] = if (!$global:CACHE.Contains('docker-buildx-checksums')) {
    [System.Text.Encoding]::UTF8.GetString( (Invoke-WebRequest https://github.com/docker/buildx/releases/download/$DOCKER_BUILDX_VERSION/checksums.txt).Content )
}else {
    $global:CACHE['docker-buildx-checksums']
}
@"
# Install docker buildx plugin. See: https://github.com/docker/buildx
USER root
RUN set -eux; \
    case "`$( uname -m )" in \
        'x86_64')  \
            URL=https://github.com/docker/buildx/releases/download/$DOCKER_BUILDX_VERSION/$( $checksums -split "`n" | ? { $_ -match 'linux-amd64' } | % { $_ -split '\s' } | Select-Object -Last 1 ); \
            SHA256=$( $checksums -split "`n" | ? { $_ -match 'linux-amd64' } | % { $_ -split '\s' } | Select-Object -First 1 ); \
            ;; \
        'armhf')  \
            URL=https://github.com/docker/buildx/releases/download/$DOCKER_BUILDX_VERSION/$( $checksums -split "`n" | ? { $_ -match 'linux-arm-v6' } | % { $_ -split '\s' } | Select-Object -Last 1 ); \
            SHA256=$( $checksums -split "`n" | ? { $_ -match 'linux-arm-v6' } | % { $_ -split '\s' } | Select-Object -First 1 ); \
            ;; \
        'armv7') \
            URL=https://github.com/docker/buildx/releases/download/$DOCKER_BUILDX_VERSION/$( $checksums -split "`n" | ? { $_ -match 'linux-arm-v7' } | % { $_ -split '\s' } | Select-Object -Last 1 ); \
            SHA256=$( $checksums -split "`n" | ? { $_ -match 'linux-arm-v7' } | % { $_ -split '\s' } | Select-Object -First 1 ); \
            ;; \
        'aarch64') \
            URL=https://github.com/docker/buildx/releases/download/$DOCKER_BUILDX_VERSION/$( $checksums -split "`n" | ? { $_ -match 'linux-arm64' } | % { $_ -split '\s' } | Select-Object -Last 1 ); \
            SHA256=$( $checksums -split "`n" | ? { $_ -match 'linux-arm64' } | % { $_ -split '\s' } | Select-Object -First 1 ); \
            ;; \
        'ppc64le') \
            URL=https://github.com/docker/buildx/releases/download/$DOCKER_BUILDX_VERSION/$( $checksums -split "`n" | ? { $_ -match 'linux-ppc64le' } | % { $_ -split '\s' } | Select-Object -Last 1 ); \
            SHA256=$( $checksums -split "`n" | ? { $_ -match 'linux-ppc64le' } | % { $_ -split '\s' } | Select-Object -First 1 ); \
            ;; \
        'riscv64') \
            URL=https://github.com/docker/buildx/releases/download/$DOCKER_BUILDX_VERSION/$( $checksums -split "`n" | ? { $_ -match 'linux-riscv64' } | % { $_ -split '\s' } | Select-Object -Last 1 ); \
            SHA256=$( $checksums -split "`n" | ? { $_ -match 'linux-riscv64' } | % { $_ -split '\s' } | Select-Object -First 1 ); \
            ;; \
        's390x') \
            URL=https://github.com/docker/buildx/releases/download/$DOCKER_BUILDX_VERSION/$( $checksums -split "`n" | ? { $_ -match 'linux-s390x' } | % { $_ -split '\s' } | Select-Object -Last 1 ); \
            SHA256=$( $checksums -split "`n" | ? { $_ -match 'linux-s390x' } | % { $_ -split '\s' } | Select-Object -First 1 ); \
            ;; \
        *) \
            echo "Architecture not supported"; \
            exit 1; \
            ;; \
    esac; \
    wget -qO- "`$URL" > docker-buildx \
    && sha256sum docker-buildx | grep "^`$SHA256 " \
    && mkdir -pv /usr/libexec/docker/cli-plugins \
    && mv -v docker-buildx /usr/libexec/docker/cli-plugins/docker-buildx \
    && chmod +x /usr/libexec/docker/cli-plugins/docker-buildx \
    && docker buildx version


"@
        }
        if ($c -match 'pwsh-([^-]+)') {
            $v = $matches[1]
            @"
USER root

# Install pwsh
# See: https://learn.microsoft.com/en-us/powershell/scripting/install/install-alpine?view=powershell-7.3
RUN apk add --no-cache \
    ca-certificates \
    less \
    ncurses-terminfo-base \
    krb5-libs \
    libgcc \
    libintl \
    libssl1.1 \
    libstdc++ \
    tzdata \
    userspace-rcu \
    zlib \
    icu-libs \
    curl
RUN apk -X https://dl-cdn.alpinelinux.org/alpine/edge/main add --no-cache lttng-ust
RUN mkdir -p /opt/microsoft/powershell/7 \
    && curl -sSL https://github.com/PowerShell/PowerShell/releases/download/v$v/powershell-$v-linux-alpine-x64.tar.gz | tar -C /opt/microsoft/powershell/7 -zxf - \
    && chmod +x /opt/microsoft/powershell/7/pwsh \
    && ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh
# Disable telemetry for powershell 7.0.0 and above and .NET core: https://github.com/PowerShell/PowerShell/issues/16234#issuecomment-942139350
ENV POWERSHELL_CLI_TELEMETRY_OPTOUT=1
ENV POWERSHELL_TELEMETRY_OPTOUT=1
ENV POWERSHELL_UPDATECHECK=Off
ENV POWERSHELL_UPDATECHECK_OPTOUT=1
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1
ENV DOTNET_TELEMETRY_OPTOUT=1
ENV COMPlus_EnableDiagnostics=0
RUN pwsh -version

# Install modules
RUN pwsh -c 'Install-Module Pester -Force -Scope AllUsers -MinimumVersion 4.0.0 -MaximumVersion 4.10.1 -ErrorAction Stop'

# Install extensions
USER user
RUN code-server --install-extension ms-vscode.powershell@2021.12.0


"@
        }
    }
}

@"
# Remove the default code-server config file created when extensions are installed
USER user
RUN rm -fv ~/.config/code-server/config.yaml

# Symlink code to code-server
USER root
RUN ln -sfn /usr/local/bin/code-server /usr/local/bin/code

USER root
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

ENV LANG=en_US.UTF-8
USER user
WORKDIR /home/user
ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD [ "--bind-addr=0.0.0.0:8080", "--disable-telemetry", "--disable-update-check" ]

"@
