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
RUN set -eu; \
    echo "TARGETPLATFORM=$TARGETPLATFORM"; \
    echo "TARGETOS=$TARGETOS"; \
    echo "TARGETARCH=$TARGETARCH"; \
    echo "TARGETVARIANT=$TARGETVARIANT"; \
    echo "BUILDPLATFORM=$BUILDPLATFORM"; \
    echo "BUILDOS=$BUILDOS"; \
    echo "BUILDARCH=$BUILDARCH"; \
    echo "BUILDVARIANT=$BUILDVARIANT";

RUN --mount=type=secret,id=GITHUB_TOKEN \
    DEPS='alpine-sdk bash libstdc++ libc6-compat python3' \
    && apk add --no-cache $DEPS \
    # Constraint to npm 8, or else npm will fail with 'npm ERR! python is not a valid npm option'. See: https://stackoverflow.com/questions/74522956/python-is-not-a-valid-npm-option and https://jubianchi.github.io/semver-check/#/~8/8
    && apk add --no-cache 'npm~8' 'nodejs~16' \
    && npm config set python python3 \
    && GITHUB_TOKEN=$( cat /run/secrets/GITHUB_TOKEN ) npm install --global code-server@4.15.0 --unsafe-perm \
    # Fix missing dependencies. See: https://github.com/coder/code-server/issues/5530
    && cd /usr/local/lib/node_modules/code-server/lib/vscode && GITHUB_TOKEN=$( cat /run/secrets/GITHUB_TOKEN ) npm install --legacy-peer-deps \
    && code-server --version \
    && apk del $DEPS

# Install tools
RUN apk add --no-cache bash bash-completion ca-certificates curl gnupg git git-lfs github-cli iotop jq less lsblk make nano openssh-client openssl p7zip rsync tree yq

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
            URL='https://download.docker.com/linux/static/stable/x86_64/docker-24.0.7.tgz'; \
            ;; \
        'armhf') \
            URL='https://download.docker.com/linux/static/stable/armel/docker-24.0.7.tgz'; \
            ;; \
        'armv7') \
            URL='https://download.docker.com/linux/static/stable/armhf/docker-24.0.7.tgz'; \
            ;; \
        'aarch64') \
            URL='https://download.docker.com/linux/static/stable/aarch64/docker-24.0.7.tgz'; \
            ;; \
        # These architectures are no longer supported as of docker 20.10.x
        # 'ppc64le') \
        # 	URL='https://download.docker.com/linux/static/stable/ppc64le/docker-24.0.7.tgz'; \
        # 	;; \
        # 's390x') \
        # 	URL='https://download.docker.com/linux/static/stable/s390x/docker-24.0.7.tgz'; \
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
RUN wget -q https://raw.githubusercontent.com/docker/cli/master/contrib/completion/bash/docker -O /usr/share/bash-completion/completions/docker
# Post-install docker. See: https://docs.docker.com/engine/install/linux-postinstall/
RUN set -eux; \
    addgroup docker; \
    adduser user docker;
VOLUME /var/lib/docker

# Install docker-compose v1 (deprecated, but for backward compatibility)
USER root
RUN apk add --no-cache docker-compose

# Install docker-compose
RUN set -eux; \
    DOCKER_COMPOSE_VERSION=v2.23.3; \
    case "$( uname -m )" in \
        'x86') \
            URL="https://github.com/docker/compose/releases/download/v2.23.3/docker-compose-linux-x86_64"; \
            SHA256=a836e807951db448f991f303cddcc9a4ec69f4a49d58bc7d536cb91c77c04c33; \
            ;; \
        'x86_64') \
            URL="https://github.com/docker/compose/releases/download/v2.23.3/docker-compose-linux-x86_64"; \
            SHA256=a836e807951db448f991f303cddcc9a4ec69f4a49d58bc7d536cb91c77c04c33; \
            ;; \
        'armhf') \
            URL="https://github.com/docker/compose/releases/download/v2.23.3/docker-compose-linux-armv6"; \
            SHA256=b712693945360155842b578beace00effa723b604bfe1ccd6421645523e15d86; \
            ;; \
        'armv7l') \
            URL="https://github.com/docker/compose/releases/download/v2.23.3/docker-compose-linux-armv7"; \
            SHA256=4068bcbe1dd90034c8fe8d2c65b600ba793fc19bdb65db3c2dbf80b8a078de6c; \
            ;; \
        'aarch64') \
            URL="https://github.com/docker/compose/releases/download/v2.23.3/docker-compose-linux-aarch64"; \
            SHA256=71f38f0923b8a9b80ad02c823ec3207d94677547aa5c618ca41b81d29fe6b9d9; \
            ;; \
        'ppc64le') \
            URL="https://github.com/docker/compose/releases/download/v2.23.3/docker-compose-linux-ppc64le"; \
            SHA256=6110b0d30baee103c98ca5503bea24acb9d52bd333a67d3bf3c57d383c585c62; \
            ;; \
        'riscv64') \
            URL="https://github.com/docker/compose/releases/download/v2.23.3/docker-compose-linux-riscv64"; \
            SHA256=3ac26e5f272deb1364c9b8760af44c4dbd87d6faa42fc53bfec95885cfa8ae77; \
            ;; \
        's390x') \
            URL="https://github.com/docker/compose/releases/download/v2.23.3/docker-compose-linux-s390x"; \
            SHA256=2886dd4eddaea1eeb03537bdc596ec8947eb3ef7908c955284f8aad9170d3098; \
            ;; \
        *) \
            echo "Architecture not supported"; \
            exit 1; \
            ;; \
    esac; \
    FILE=docker-compose; \
    wget -q "$URL" -O "$FILE"; \
    echo "$SHA256  $FILE" | sha256sum -c -; \
    mkdir -pv /usr/libexec/docker/cli-plugins; \
    mv -v docker-compose /usr/libexec/docker/cli-plugins/docker-compose; \
    chmod +x /usr/libexec/docker/cli-plugins/docker-compose; \
    docker compose version; \
    :

# Install docker-buildx
RUN set -eux; \
    DOCKER_BUILDX_VERSION=v0.12.0; \
    case "$( uname -m )" in \
        'x86_64') \
            URL="https://github.com/docker/buildx/releases/download/v0.12.0/buildx-v0.12.0.linux-amd64"; \
            SHA256=7c393b92c148a0ce26c76a2abc99960be1d1097f0471978d41dc51d0c1a4471e; \
            ;; \
        'armhf') \
            URL="https://github.com/docker/buildx/releases/download/v0.12.0/buildx-v0.12.0.linux-arm-v6"; \
            SHA256=62d9162f526c3bb7f67768a5b0d81a8b3ad0371406dfc1f0775e4f62dfca7fe1; \
            ;; \
        'armv7l') \
            URL="https://github.com/docker/buildx/releases/download/v0.12.0/buildx-v0.12.0.linux-arm-v7"; \
            SHA256=d941d6a5b072de775222d31d9f8467b4c1b1f56e3b08d1b78f828a9244c16464; \
            ;; \
        'aarch64') \
            URL="https://github.com/docker/buildx/releases/download/v0.12.0/buildx-v0.12.0.linux-arm64"; \
            SHA256=781caebb36551b035cb9dcfaf91088543d09c73c4a2549341e6417d86b8bbb50; \
            ;; \
        'ppc64le') \
            URL="https://github.com/docker/buildx/releases/download/v0.12.0/buildx-v0.12.0.linux-ppc64le"; \
            SHA256=ab5bda4532528d6b0801c877999fce9def10c6a37624673fd13c668fdcde16b7; \
            ;; \
        'riscv64') \
            URL="https://github.com/docker/buildx/releases/download/v0.12.0/buildx-v0.12.0.linux-riscv64"; \
            SHA256=a2b846919c44128c6db9165ad24545e7e10035b6f0ad01559fcfbb2a13017127; \
            ;; \
        's390x') \
            URL="https://github.com/docker/buildx/releases/download/v0.12.0/buildx-v0.12.0.linux-s390x"; \
            SHA256=81c2ada65624e2ac6bb4123f3a3bb933d04cfb08aa45fc55dd201ba523d96d30; \
            ;; \
        *) \
            echo "Architecture not supported"; \
            exit 1; \
            ;; \
    esac; \
    FILE=docker-buildx; \
    wget -q "$URL" -O "$FILE"; \
    echo "$SHA256  $FILE" | sha256sum -c -; \
    mkdir -pv /usr/libexec/docker/cli-plugins; \
    mv -v docker-buildx /usr/libexec/docker/cli-plugins/docker-buildx; \
    chmod +x /usr/libexec/docker/cli-plugins/docker-buildx; \
    docker buildx version; \
    :

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
ENV GOLANG_VERSION 1.20.12
ENV PATH=/usr/local/go/bin:$PATH
COPY --from=golang:1.20.12-alpine /usr/local/go /usr/local/go
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
