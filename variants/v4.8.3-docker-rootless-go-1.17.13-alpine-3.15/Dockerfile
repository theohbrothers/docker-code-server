# syntax=docker/dockerfile:1
FROM alpine:3.15
ARG TARGETPLATFORM
ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT
ARG BUILDPLATFORM
ARG BUILDOS
ARG BUILDARCH
ARG BUILDVARIANT
RUN set -ex; \
    echo "TARGETPLATFORM="; \
    echo "TARGETOS="; \
    echo "TARGETARCH="; \
    echo "TARGETVARIANT="; \
    echo "BUILDPLATFORM="; \
    echo "BUILDOS="; \
    echo "BUILDARCH="; \
    echo "BUILDVARIANT=";

RUN --mount=type=secret,id=GITHUB_TOKEN \
    DEPS='alpine-sdk bash libstdc++ libc6-compat python3' \
    && apk add --no-cache $DEPS \
    # Constraint to npm 8, or else npm will fail with 'npm ERR! python is not a valid npm option'. See: https://stackoverflow.com/questions/74522956/python-is-not-a-valid-npm-option and https://jubianchi.github.io/semver-check/#/~8/8
    && apk add --no-cache 'npm~8' 'nodejs~16' \
    && npm config set python python3 \
    && GITHUB_TOKEN=$( cat /run/secrets/GITHUB_TOKEN ) npm install --global code-server@4.8.3 --unsafe-perm \
    # Fix missing dependencies. See: https://github.com/coder/code-server/issues/5530
    && cd /usr/local/lib/node_modules/code-server/lib/vscode && GITHUB_TOKEN=$( cat /run/secrets/GITHUB_TOKEN ) npm install --legacy-peer-deps \
    && code-server --version \
    && apk del $DEPS

# Install tools
RUN apk add --no-cache bash bash-completion ca-certificates curl gnupg git git-lfs iotop jq less lsblk make nano openssh-client openssl p7zip rsync tree yq

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
    && curl -sSL https://github.com/PowerShell/PowerShell/releases/download/v7.2.8/powershell-7.2.8-linux-alpine-x64.tar.gz | tar -C /opt/microsoft/powershell/7 -zxf - \
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

# Add a default settings.json
USER user
COPY --chown=1000:1000 settings.json /home/user/.local/share/code-server/User/settings.json

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
    case "$( uname -m )" in \
        'x86_64') \
            URL='https://download.docker.com/linux/static/stable/x86_64/docker-20.10.23.tgz'; \
            ;; \
        'armhf') \
            URL='https://download.docker.com/linux/static/stable/armel/docker-20.10.23.tgz'; \
            ;; \
        'armv7') \
            URL='https://download.docker.com/linux/static/stable/armhf/docker-20.10.23.tgz'; \
            ;; \
        'aarch64') \
            URL='https://download.docker.com/linux/static/stable/aarch64/docker-20.10.23.tgz'; \
            ;; \
        # These architectures are no longer supported as of docker 20.10.x
        # 'ppc64le') \
        # 	URL='https://download.docker.com/linux/static/stable/ppc64le/docker-20.10.23.tgz'; \
        # 	;; \
        # 's390x') \
        # 	URL='https://download.docker.com/linux/static/stable/s390x/docker-20.10.23.tgz'; \
        # 	;; \
        *) \
            echo "Architecture not supported"; \
            exit 1; \
            ;; \
    esac; \
    wget -q "$URL" -O docker.tgz; \
    tar -xvf docker.tgz --strip-components=1 --no-same-owner --no-same-permissions -C /usr/local/bin; \
    ls -al /usr/local/bin; \
    rm -v docker.tgz; \
    containerd --version; \
    ctr --version; \
    docker --version; \
    dockerd --version; \
    runc --version
# Install bash completion
RUN wget -q https://raw.githubusercontent.com/docker/cli/v20.10.23/contrib/completion/bash/docker -O /usr/share/bash-completion/completions/docker
# Post-install docker. See: https://docs.docker.com/engine/install/linux-postinstall/
RUN set -eux; \
    addgroup docker; \
    adduser user docker;
VOLUME /var/lib/docker

# Install rootless docker. See: https://docs.docker.com/engine/security/rootless/
USER root
RUN apk add --no-cache iproute2 fuse-overlayfs
RUN set -eux; \
    echo user:100000:65536 >> /etc/subuid; \
    echo user:100000:65536 >> /etc/subgid
RUN set -eux; \
    case "$( uname -m )" in \
        'x86_64') \
            URL='https://download.docker.com/linux/static/stable/x86_64/docker-rootless-extras-20.10.23.tgz'; \
            ;; \
        'aarch64') \
            URL='https://download.docker.com/linux/static/stable/aarch64/docker-rootless-extras-20.10.23.tgz'; \
            ;; \
        'armv7') \
            URL='https://download.docker.com/linux/static/stable/armhf/docker-rootless-extras-20.10.23.tgz'; \
            ;; \
        'aarch64') \
            URL='https://download.docker.com/linux/static/stable/aarch64/docker-rootless-extras-20.10.23.tgz'; \
            ;; \
        *) \
            echo "Architecture not supported"; \
            exit 1; \
            ;; \
    esac; \
    wget -q "$URL" -O docker-rootless-extras.tgz; \
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

# Install docker-compose v1 (deprecated, but for backward compatibility)
USER root
RUN apk add --no-cache docker-compose

# Install docker compose v2. See: https://github.com/docker/compose/releases/
USER root
RUN set -eux; \
    case "$( uname -m )" in \
        'x86_64')  \
            URL=https://github.com/docker/compose/releases/download/v2.15.1/docker-compose-linux-x86_64; \
            SHA256=bcfd9ea51dee4c19dccdfaeef0e7956ef68bf14f3d175933742061a7271ef0f5; \
            ;; \
        'armhf')  \
            URL=https://github.com/docker/compose/releases/download/v2.15.1/docker-compose-linux-armv6; \
            SHA256=a8934600100af88f535eb50b45c7d8d2ac37835221803ba2910e0b167b3af22e; \
            ;; \
        'armv7') \
            URL=https://github.com/docker/compose/releases/download/v2.15.1/docker-compose-linux-armv7; \
            SHA256=e5b03ac1258ad4243af0ac4afcb1c6cc8c9956b2483a50309cdb38cdb8387e37; \
            ;; \
        'aarch64') \
            URL=https://github.com/docker/compose/releases/download/v2.15.1/docker-compose-linux-aarch64; \
            SHA256=14d31297794868520cb2e61b543bb1c821aaa484af22b397904314ae8227f6a2; \
            ;; \
        'ppc64le') \
            URL=https://github.com/docker/compose/releases/download/v2.15.1/docker-compose-linux-ppc64le; \
            SHA256=bdada874a26d382b20ced7c170707a1ebcf9f20d7d6f394b962076968473ca9c; \
            ;; \
        'riscv64') \
            URL=https://github.com/docker/compose/releases/download/v2.15.1/docker-compose-linux-riscv64; \
            SHA256=9cc1b9c8de313a1e43b8f3dcca47c29eeb87af3de24c67448c463bf882166430; \
            ;; \
        's390x') \
            URL=https://github.com/docker/compose/releases/download/v2.15.1/docker-compose-linux-s390x; \
            SHA256=cf311824af115d0bece5d5d60a73464912dad07cdd00fdaa469dabbcad60f289; \
            ;; \
        *) \
            echo "Architecture not supported"; \
            exit 1; \
            ;; \
    esac; \
    wget -qO- "$URL" > docker-compose \
    && sha256sum docker-compose | grep "^$SHA256 " \
    && mkdir -pv /usr/libexec/docker/cli-plugins \
    && mv -v docker-compose /usr/libexec/docker/cli-plugins/docker-compose \
    && chmod +x /usr/libexec/docker/cli-plugins/docker-compose \
    && docker compose version

# Install docker buildx plugin. See: https://github.com/docker/buildx
USER root
RUN set -eux; \
    case "$( uname -m )" in \
        'x86_64')  \
            URL=https://github.com/docker/buildx/releases/download/v0.9.1/buildx-v0.9.1.linux-amd64; \
            SHA256=a7fb95177792ca8ffc7243fad7bf2f33738b8b999a184b6201f002a63c43d136; \
            ;; \
        'armhf')  \
            URL=https://github.com/docker/buildx/releases/download/v0.9.1/buildx-v0.9.1.linux-arm-v6; \
            SHA256=159925b4e679eb66e7f0312c7d57a97e68a418c1fa602a00dd8b29b6406768f0; \
            ;; \
        'armv7') \
            URL=https://github.com/docker/buildx/releases/download/v0.9.1/buildx-v0.9.1.linux-arm-v7; \
            SHA256=ba8e5359ce9ba24fec6da07f73591c1b20ac0797a2248b0ef8088f57ae3340fc; \
            ;; \
        'aarch64') \
            URL=https://github.com/docker/buildx/releases/download/v0.9.1/buildx-v0.9.1.linux-arm64; \
            SHA256=bbf6a76bf9aef9c5759ff225b97ce23a24fc11e4fa3cdcae36e5dcf1de2cffc5; \
            ;; \
        'ppc64le') \
            URL=https://github.com/docker/buildx/releases/download/v0.9.1/buildx-v0.9.1.linux-ppc64le; \
            SHA256=1b2441886e556c720c1bf12f18f240113cc45f9eb404c0f162166ca1c96c1b60; \
            ;; \
        'riscv64') \
            URL=https://github.com/docker/buildx/releases/download/v0.9.1/buildx-v0.9.1.linux-riscv64; \
            SHA256=c32372dad653fc70eb756b2cffd026e74425e807c01accaeed4559da881ff57c; \
            ;; \
        's390x') \
            URL=https://github.com/docker/buildx/releases/download/v0.9.1/buildx-v0.9.1.linux-s390x; \
            SHA256=90b0ecf315d741888920dddeac9fe2e141123c4fe79465b7b10fe23521c9c366; \
            ;; \
        *) \
            echo "Architecture not supported"; \
            exit 1; \
            ;; \
    esac; \
    wget -qO- "$URL" > docker-buildx \
    && sha256sum docker-buildx | grep "^$SHA256 " \
    && mkdir -pv /usr/libexec/docker/cli-plugins \
    && mv -v docker-buildx /usr/libexec/docker/cli-plugins/docker-buildx \
    && chmod +x /usr/libexec/docker/cli-plugins/docker-buildx \
    && docker buildx version

# Install binary tool(s)
RUN set -eux; \
    wget https://github.com/GoogleContainerTools/container-diff/releases/download/v0.17.0/container-diff-linux-amd64 -O container-diff; \
    sha256sum container-diff | grep '^818c219ce9f9670cd5c766b9da5036cf75bbf98bc99eb258f5e8f90e80367c88 '; \
    mv container-diff /usr/local/bin/container-diff; \
    chmod +x /usr/local/bin/container-diff; \
    container-diff version

# Install golang binaries from official golang image
# See: https://go.dev/dl/
USER root
ENV GOLANG_VERSION 1.17.13
ENV PATH=/usr/local/go/bin:$PATH
COPY --from=golang:1.17.13-alpine /usr/local/go /usr/local/go
RUN go version

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
