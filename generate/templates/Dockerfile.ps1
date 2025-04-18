$local:VERSIONS = @( Get-Content $PSScriptRoot/../definitions/versions.json -Encoding utf8 -raw | ConvertFrom-Json )

@"
# syntax=docker/dockerfile:1
FROM $( $VARIANT['_metadata']['distro'] ):$( $VARIANT['_metadata']['distro_version'] )
ARG TARGETPLATFORM
ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT
ARG BUILDPLATFORM
ARG BUILDOS
ARG BUILDARCH
ARG BUILDVARIANT
RUN set -eu; \
    echo "TARGETPLATFORM=`$TARGETPLATFORM"; \
    echo "TARGETOS=`$TARGETOS"; \
    echo "TARGETARCH=`$TARGETARCH"; \
    echo "TARGETVARIANT=`$TARGETVARIANT"; \
    echo "BUILDPLATFORM=`$BUILDPLATFORM"; \
    echo "BUILDOS=`$BUILDOS"; \
    echo "BUILDARCH=`$BUILDARCH"; \
    echo "BUILDVARIANT=`$BUILDVARIANT";

RUN --mount=type=secret,id=GITHUB_TOKEN \
    set -eux; \
    DEPS='alpine-sdk bash libstdc++ libc6-compat python3'; \
    apk add --no-cache `$DEPS; \
    # Constraint to npm 8, or else npm will fail with 'npm ERR! `python` is not a valid npm option'. See: https://stackoverflow.com/questions/74522956/python-is-not-a-valid-npm-option and https://jubianchi.github.io/semver-check/#/~8/8
$(
if ([version]$VARIANT['_metadata']['package_version'] -ge [version]'4.90') {
@"
    apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/v3.15/main npm~8; \
    apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/v3.20/main nodejs~20; \
    # Fix python3.12 failing with: ModuleNotFoundError: No module named 'distutils' on alpine:3.20
    # apk add --no-cache py3-setuptools; \
    # Fix errors about missing spdlog
    # apk add --no-cache spdlog; \
    # Install kerberos dependencies https://github.com/coder/code-server/issues/6535
    apk add --no-cache krb5-dev; \
"@
} elseif ([version]$VARIANT['_metadata']['package_version'] -ge [version]'4.17' -and [version]$VARIANT['_metadata']['package_version'] -lt [version]'4.90') {
@"
    apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/v3.15/main npm~8; \
    apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/v3.17/main nodejs~18; \
    # Install kerberos dependencies https://github.com/coder/code-server/issues/6535
    apk add --no-cache krb5-dev; \
"@
} else {
@"
    apk add --no-cache npm~8 nodejs~16; \
"@
} )
    npm config set python python3; \
    # Use 'NODE_API_EXPERIMENTAL_NOGC_ENV_OPT_OUT' to fix node 18.20 and 20.12 making experimental API the default, which breaks builds
    # Use '-U_FORTIFY_SOURCE' to fix vsnprintf errors in alpine: https://gitlab.alpinelinux.org/alpine/aports/-/issues/8626
    # Use '-DUSE_IPO=OFF -DWHOLE_PROGRAM_OPTIMISATION=OFF' to fix lto-wrapper errors?
    ( set +x; export GITHUB_TOKEN=`$( cat /run/secrets/GITHUB_TOKEN ); set -x; CXXFLAGS='-DNODE_API_EXPERIMENTAL_NOGC_ENV_OPT_OUT$(
        if ([version]$VARIANT['_metadata']['package_version'] -ge [version]'4.90') {
            ' -U_FORTIFY_SOURCE'
        }
    )' npm install --global code-server@$( $VARIANT['_metadata']['package_version'] ) --unsafe-perm ); \
    # Fix missing dependencies. See: https://github.com/coder/code-server/issues/5530
    ( cd /usr/local/lib/node_modules/code-server/lib/vscode; set +x; export GITHUB_TOKEN=`$( cat /run/secrets/GITHUB_TOKEN ); set -x; CXXFLAGS='-DNODE_API_EXPERIMENTAL_NOGC_ENV_OPT_OUT$(
        if ([version]$VARIANT['_metadata']['package_version'] -ge [version]'4.90') {
            ' -U_FORTIFY_SOURCE'
        }
    )' npm install --legacy-peer-deps ); \
    code-server --version; \
    apk del `$DEPS

# Install tools
RUN set -eux; \
    apk add --no-cache bash bash-completion ca-certificates curl gnupg git git-lfs github-cli iotop jq less lsblk make nano openssh-client openssl p7zip rsync tree yq

# Install pwsh
# See: https://learn.microsoft.com/en-us/powershell/scripting/install/install-alpine?view=powershell-7.3
RUN set -eux; \
    apk add --no-cache \
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
RUN set -eux; \
    mkdir -p /opt/microsoft/powershell/7; \
    curl -sSL https://github.com/PowerShell/PowerShell/releases/download/v7.2.8/powershell-7.2.8-linux-alpine-x64.tar.gz | tar -C /opt/microsoft/powershell/7 -zxf -; \
    chmod +x /opt/microsoft/powershell/7/pwsh; \
    ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh
# Disable telemetry for powershell 7.0.0 and above and .NET core: https://github.com/PowerShell/PowerShell/issues/16234#issuecomment-942139350
ENV POWERSHELL_CLI_TELEMETRY_OPTOUT=1
ENV POWERSHELL_TELEMETRY_OPTOUT=1
ENV POWERSHELL_UPDATECHECK=Off
ENV POWERSHELL_UPDATECHECK_OPTOUT=1
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1
ENV DOTNET_TELEMETRY_OPTOUT=1
ENV COMPlus_EnableDiagnostics=0
RUN pwsh -version
# Install pwsh module(s)
RUN pwsh -c 'Install-Module Pester -Force -Scope AllUsers -MinimumVersion 4.0.0 -MaximumVersion 4.10.1 -ErrorAction Stop'

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
# github. Install the latest compatible version
RUN code-server --install-extension github.vscode-pull-request-github
# gitlab
RUN code-server --install-extension gitlab.gitlab-workflow@3.60.0
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
# pwsh
RUN code-server --install-extension ms-vscode.powershell@2021.12.0
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


"@
foreach ($c in $VARIANT['_metadata']['components']) {
    if ($c -eq 'docker' -or $c -eq 'docker-rootless') {
        $DOCKER_VERSION = $global:VERSIONS.docker.versions[0]
@"
# Install docker
# See: https://github.com/moby/moby/blob/v20.10.22/project/PACKAGERS.md
# Install docker-cli dependencies
USER root
RUN set -eux; \
    apk add --no-cache \
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
RUN wget -q https://raw.githubusercontent.com/docker/cli/master/contrib/completion/bash/docker -O /usr/share/bash-completion/completions/docker
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
RUN set -eux; \
    mkdir /run/user; \
    chmod 1777 /run/user
# Create /var/lib/docker
RUN set -eux; \
    mkdir -p /home/user/.local/share/docker; \
    chown user:user /home/user/.local/share/docker
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

        $DOCKER_COMPOSE_VERSION = "v$( $local:VERSIONS.'docker-compose'.versions[0] )"
        Generate-DownloadBinary @{
            binary = 'docker-compose'
            version = $DOCKER_COMPOSE_VERSION
            checksumsUrl = "https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/checksums.txt"
            archiveformat = ''
            destination = '/usr/libexec/docker/cli-plugins/docker-compose'
            testCommand = 'docker compose version'
        }

        $DOCKER_BUILDX_VERSION = "v$( $local:VERSIONS.'docker-buildx'.versions[0] )"
        Generate-DownloadBinary @{
            binary = 'docker-buildx'
            version = $DOCKER_BUILDX_VERSION
            archiveformat = ''
            checksumsUrl = "https://github.com/docker/buildx/releases/download/$DOCKER_BUILDX_VERSION/checksums.txt"
            destination = '/usr/libexec/docker/cli-plugins/docker-buildx'
            testCommand = 'docker buildx version'
        }

@"
# Install binary tool(s)
RUN set -eux; \
    wget https://github.com/GoogleContainerTools/container-diff/releases/download/v0.17.0/container-diff-linux-amd64 -O container-diff; \
    sha256sum container-diff | grep '^818c219ce9f9670cd5c766b9da5036cf75bbf98bc99eb258f5e8f90e80367c88 '; \
    mv container-diff /usr/local/bin/container-diff; \
    chmod +x /usr/local/bin/container-diff; \
    container-diff version


"@
    }

    if ($c -match 'go-([^-]+)') {
        $v = $matches[1]
@"
# Install golang binaries from official golang image
# See: https://go.dev/dl/
USER root
ENV GOLANG_VERSION $v
ENV PATH=/usr/local/go/bin:`$PATH
COPY --from=golang:$v-alpine /usr/local/go /usr/local/go
RUN go version


"@

            # Not installing from official binaries. Binaries may not compatible with Alpine (esp go1.20). See: https://github.com/golang/go/issues/18773 and https://github.com/golang/go/issues/38536
            # $global:CACHE['golang-releases'] = if (!$global:CACHE.Contains('golang-releases')) {
            #     # Get all golang releases. See: https://github.com/golang/go/issues/23746
            #     $releases = Invoke-RestMethod 'https://go.dev/dl/?mode=json&include=all'
            #     # Build a hash for fast retrieval
            #     # E.g. { "go1.20.2": { release: {}, files: { "linux-amd64": {} } }
            #     $h = @{}
            #     $releases | % {
            #         $h[$_.version] = @{
            #             release = $_
            #             files = @{}
            #         }
            #         $_.files | % {
            #             $h[$_.version]['files']["$( $_.os )-$( $_.arch )"] = $_
            #         }
            #     }
            #     $h
            # }else {
            #     $global:CACHE['golang-releases']
            # }
            # $release = $global:CACHE['golang-releases']["go$v"]

# Not installing from official binaries. Binaries may not compatible with Alpine (esp go1.20). See: https://github.com/golang/go/issues/18773 and https://github.com/golang/go/issues/38536
# @"
# RUN set -eux; \
#     case "`$( uname -m )" in \
#         'x86_64')  \
#             URL=https://go.dev/dl/$( $release['files']['linux-amd64'].filename ); \
#             SHA256=$( $release['files']['linux-amd64'].sha256 ) \
#             ;; \
#         'armhf')  \
#             URL=https://go.dev/dl/$( $release['files']['linux-amd64'].filename ); \
#             SHA256=$( $release['files']['linux-armv6l'].sha256 ) \
#             ;; \
#         'armv7') \
#             URL=https://go.dev/dl/$( $release['files']['linux-amd64'].filename ); \
#             SHA256=$( $release['files']['linux-armv6l'].sha256 ) \
#             ;; \
#         'aarch64') \
#             URL=https://go.dev/dl/$( $release['files']['linux-amd64'].filename ); \
#             SHA256=$( $release['files']['linux-arm64'].sha256 ) \
#             ;; \
#         'ppc64le') \
#             URL=https://go.dev/dl/$( $release['files']['linux-amd64'].filename ); \
#             SHA256=$( $release['files']['linux-ppc64le'].sha256 ) \
#             ;; \
#         's390x') \
#             URL=https://go.dev/dl/$( $release['files']['linux-amd64'].filename ); \
#             SHA256=$( $release['files']['linux-s390x'].sha256 ) \
#             ;; \
#         *) \
#             echo "Architecture not supported"; \
#             exit 1; \
#             ;; \
#     esac; \
#     wget -qO- "`$URL" > go.tar.gz; \
#     sha256sum go.tar.gz | grep "^`$SHA256 "; \
#     tar -xzf go.tar.gz -C /usr/local; \
#     go version; \
#     rm -fv go.tar.gz;

# "@

@"
# Install development tools
RUN set -eux; \
    export GOBIN=/usr/local/bin; \
    go install github.com/go-delve/delve/cmd/dlv@v1.20.1; \
    dlv version; \
    go install golang.org/x/tools/gopls@v0.11.0; \
    gopls version; \
    rm -rf ~/go;

# Install extensions
USER user
RUN code-server --install-extension golang.go@0.38.0


"@
    }
}

@"
# Add a default settings.json
USER user
COPY --chown=1000:1000 settings.json /home/user/.local/share/code-server/User/settings.json

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
