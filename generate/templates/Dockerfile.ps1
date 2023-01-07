if (!$VARIANT['_metadata']['base_tag']) {
    # Base build
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
    && apk add --no-cache npm nodejs \
    && npm config set python python3 \
    && GITHUB_TOKEN=`$( cat /run/secrets/GITHUB_TOKEN ) npm install --global code-server@$( $VARIANT['_metadata']['package_version'] ) --unsafe-perm \
    # Fix missing dependencies. See: https://github.com/coder/code-server/issues/5530
    && cd /usr/local/lib/node_modules/code-server/lib/vscode && GITHUB_TOKEN=`$( cat /run/secrets/GITHUB_TOKEN ) npm install --legacy-peer-deps \
    && code-server --version \
    && apk del `$DEPS

RUN apk add --no-cache bash bash-completion ca-certificates curl gnupg git git-lfs jq less nano openssh-client openssl tree

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
    # Incremental build
    @'
ARG BASE_IMAGE
FROM $BASE_IMAGE


'@
    foreach ($c in $VARIANT['_metadata']['components']) {
        if ($c -eq 'docker') {
@'
USER root

# Install docker
# See: https://github.com/moby/moby/blob/v20.10.22/project/PACKAGERS.md
# Install docker client dependencies
RUN apk add --no-cache \
        ca-certificates \
        git \
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
RUN apk add --no-cache docker
RUN adduser user docker

# Install docker compose v2
RUN apk add --no-cache docker-cli-compose

# Install docker-compose v1 (deprecated, but for backward compatibility)
RUN apk add --no-cache docker-compose
'@

        }
        if ($c -eq 'docker-rootless') {
@'
USER root

# Install rootless docker
# See: https://docs.docker.com/engine/security/rootless/
RUN apk add --no-cache shadow-uidmap fuse-overlayfs iproute2 iptables ip6tables
RUN echo user:100000:65536 >/etc/subuid
RUN echo user:100000:65536 >/etc/subgid
USER user
RUN wget -qO- https://get.docker.com/rootless | sh
ENV XDG_RUNTIME_DIR=/home/user/.docker/run
ENV PATH=/home/user/bin:$PATH
ENV DOCKER_HOST=unix:///home/user/.docker/run/docker.sock

USER root

# Install docker compose v2
RUN apk add --no-cache docker-cli-compose

# Install docker-compose v1 (deprecated, but for backward compatibility)
RUN apk add --no-cache docker-compose
'@
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

USER root
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

ENV LANG=en_US.UTF-8
USER user
WORKDIR /home/user
CMD [ "/docker-entrypoint.sh" ]
"@
